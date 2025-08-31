package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"time"

	"cloud.google.com/go/pubsub/v2"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sts"
)

// LambdaEvent represents the input event from Step Function
type LambdaEvent struct {
	WorkflowID  string `json:"workflow_id"`
	ExecutionID string `json:"execution_id"`
}

// LambdaResponse represents the response from the lambda function
type LambdaResponse struct {
	Message     string `json:"message"`
	MessageID   string `json:"message_id,omitempty"`
	WorkflowID  string `json:"workflow_id"`
	ExecutionID string `json:"execution_id"`
	Success     bool   `json:"success"`
	Error       string `json:"error,omitempty"`
	ErrorClass  string `json:"error_class,omitempty"`
}

// MessageData represents the data to be published to Pub/Sub
type MessageData struct {
	CustomMessage   string `json:"custom_message"`
	Timestamp       string `json:"timestamp,omitempty"`
	Source          string `json:"source"`
	WorkflowID      string `json:"workflow_id"`
	ExecutionID     string `json:"execution_id"`
	LambdaRequestID string `json:"lambda_request_id"`
	TriggerTime     string `json:"trigger_time,omitempty"`
}

// LambdaContext represents the lambda context
type LambdaContext struct {
	AwsRequestID          string
	RemainingTimeInMillis int64
}

func main() {
	lambda.Start(handler)
}

func handler(ctx context.Context, event LambdaEvent) (LambdaResponse, error) {
	log.Printf("Trigger DAG Lambda function started")
	eventJSON, _ := json.MarshalIndent(event, "", "  ")
	log.Printf("Event: %s", string(eventJSON))

	// Get environment variables
	pubsubTopicID := os.Getenv("PUBSUB_TOPIC_ID")
	gcpProjectID := os.Getenv("GCP_PROJECT_ID")
	googleAppCreds := os.Getenv("GOOGLE_APPLICATION_CREDENTIALS")

	log.Printf("Google Application Credentials: %s", googleAppCreds)
	log.Printf("Pub/Sub Topic: %s", pubsubTopicID)
	log.Printf("GCP Project ID: %s", gcpProjectID)

	// Get caller identity to verify WIF is working
	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		return LambdaResponse{
			Message:    "Error occurred while triggering DAG",
			Error:      fmt.Sprintf("Failed to load AWS config: %v", err),
			ErrorClass: "ConfigError",
			Success:    false,
		}, nil
	}

	stsClient := sts.NewFromConfig(cfg)
	callerIdentity, err := stsClient.GetCallerIdentity(ctx, &sts.GetCallerIdentityInput{})
	if err != nil {
		return LambdaResponse{
			Message:    "Error occurred while triggering DAG",
			Error:      fmt.Sprintf("Failed to get caller identity: %v", err),
			ErrorClass: "STSError",
			Success:    false,
		}, nil
	}

	callerIdentityJSON, _ := json.MarshalIndent(callerIdentity, "", "  ")
	log.Printf("Caller Identity: %s", string(callerIdentityJSON))

	// Create Pub/Sub client
	pubsubClient, err := pubsub.NewClient(ctx, gcpProjectID)
	if err != nil {
		return LambdaResponse{
			Message:    "Error occurred while triggering DAG",
			Error:      fmt.Sprintf("Failed to create Pub/Sub client: %v", err),
			ErrorClass: "PubSubClientError",
			Success:    false,
		}, nil
	}
	defer pubsubClient.Close()

	// Get the publisher client
	publisher := pubsubClient.Publisher(pubsubTopicID)

	// Prepare the message data
	messageData := MessageData{
		CustomMessage:   fmt.Sprintf("Hello from AWS Step Function! Workflow: %s", event.WorkflowID),
		Source:          "aws_step_function",
		WorkflowID:      event.WorkflowID,
		ExecutionID:     event.ExecutionID,
		LambdaRequestID: "go-lambda-request-id", // Go lambda doesn't provide request ID in the same way
	}

	// Convert to JSON string
	messageJSON, err := json.Marshal(messageData)
	if err != nil {
		return LambdaResponse{
			Message:    "Error occurred while triggering DAG",
			Error:      fmt.Sprintf("Failed to marshal message data: %v", err),
			ErrorClass: "JSONMarshalError",
			Success:    false,
		}, nil
	}

	log.Printf("Publishing message to Pub/Sub: %s", string(messageJSON))

	// Publish the message
	publishCtx, cancel := context.WithTimeout(ctx, 30*time.Second)
	defer cancel()

	result := publisher.Publish(publishCtx, &pubsub.Message{
		Data: messageJSON,
	})

	// Wait for the message to be published
	messageID, err := result.Get(publishCtx)
	if err != nil {
		return LambdaResponse{
			Message:    "Error occurred while triggering DAG",
			Error:      fmt.Sprintf("Failed to publish message: %v", err),
			ErrorClass: "PublishError",
			Success:    false,
		}, nil
	}

	log.Printf("Message published successfully with ID: %s", messageID)

	response := LambdaResponse{
		Message:     fmt.Sprintf("Successfully published message to Pub/Sub topic: %s", pubsubTopicID),
		MessageID:   messageID,
		WorkflowID:  event.WorkflowID,
		ExecutionID: event.ExecutionID,
		Success:     true,
	}

	responseJSON, _ := json.MarshalIndent(response, "", "  ")
	log.Printf("Result: %s", string(responseJSON))

	return response, nil
}
