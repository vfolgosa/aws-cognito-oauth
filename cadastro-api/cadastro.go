package main

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

// The input type and the output type are defined by the API Gateway.
func handleRequest(req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {

	jsonReq, errParserReq := json.Marshal(req)
	if errParserReq != nil {
		fmt.Println("ERRO parser Request -----> ", errParserReq)
		return events.APIGatewayProxyResponse{StatusCode: 500}, errParserReq
	}

	fmt.Println("Event -----> ", string(jsonReq))

	res := events.APIGatewayProxyResponse{
		StatusCode: http.StatusOK,
		Headers:    map[string]string{"Content-Type": "application/json; charset=utf-8"},
		Body:       string(jsonReq),
	}
	return res, nil
}

func main() {
	lambda.Start(handleRequest)
}
