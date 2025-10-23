const AWS = require('aws-sdk');
const dynamo = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
    let body;
    try {
        body = event.body ? JSON.parse(event.body) : {};
    } catch (error) {
        return {
            statusCode: 400,
            body: JSON.stringify({ error: 'Invalid JSON in request body' })
        };
    }

    // Validate required fields
    if (!body.name || !body.email || !body.message) {
        return {
            statusCode: 400,
            body: JSON.stringify({ error: 'Missing required fields: name, email, message' })
        };
    }

    const params = {
        TableName: 'ContactForm',
        Item: {
            id: Date.now().toString(),
            name: body.name,
            email: body.email,
            message: body.message
        }
    };

    try {
        await dynamo.put(params).promise();
        return {
            statusCode: 200,
            body: JSON.stringify('Form data saved!')
        };
    } catch (error) {
        return {
            statusCode: 500,
            body: JSON.stringify({ error: 'Failed to save to DynamoDB: ' + error.message })
        };
    }
};