const AWS = require("aws-sdk");
const dynamoDB = new AWS.DynamoDB.DocumentClient();
const ses = new AWS.SES();

const TABLE_NAME = process.env.TABLE_NAME;
const ADMIN_EMAIL = process.env.SES_ADMIN_EMAIL;

if (!TABLE_NAME || !ADMIN_EMAIL) {
    throw new Error("Environment variables TABLE_NAME and SES_ADMIN_EMAIL must be set");
}

exports.handler = async (event) => {
    if (event.httpMethod === "OPTIONS") {
        console.log("Received OPTIONS request **********");
        return {
            statusCode: 200,
            headers: {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "OPTIONS,POST",
                "Access-Control-Allow-Headers": "Content-Type",
                "Access-Control-Allow-Credentials": true
            },
            "body": JSON.stringify({ message: "CORS preflight successful" })
        };
    }

    let requestBody;
    if (event.body) {
        try {
            requestBody = JSON.parse(event.body);
            console.log("Received request body (JSON):", requestBody);
        } catch (error) {
            requestBody = event.body;
            console.log("Received request body (non-JSON):", requestBody);
        }
    } else {
        console.log("No request body received");
        return {
            statusCode: 400,
            headers: {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "OPTIONS,POST",
                "Access-Control-Allow-Headers": "Content-Type",
                "Access-Control-Allow-Credentials": true
            },
            body: JSON.stringify({ error: "Request body is missing" })
        };
    }

    try {
        const { name, email, message } = requestBody;
        if (!name || !email || !message) {
            return {
                statusCode: 400,
                headers: {
                    "Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Methods": "OPTIONS,POST",
                    "Access-Control-Allow-Headers": "Content-Type",
                    "Access-Control-Allow-Credentials": true
                },
                body: JSON.stringify({ error: "Missing required fields: name, email, message" })
            };
        }

        // Save data to DynamoDB
        const putParams = {
            TableName: TABLE_NAME,
            Item: { email, name, message, timestamp: new Date().toISOString() }
        };
        await dynamoDB.put(putParams).promise();
        console.log("Data stored in DynamoDB:", putParams.Item);

        // Send email to Admin
        await sendEmail(ADMIN_EMAIL, "New Contact Form Submission", `New message from ${name} (${email}):\n\n${message}`);
        console.log("Email sent to admin:", ADMIN_EMAIL);

        // Send confirmation email to customer
        await sendEmail(email, "Thank You for Contacting Us", `Hi ${name},\n\nThank you for reaching out. We have received your message and will get back to you soon.\n\nBest Regards,\nSupport Team`);
        console.log("Confirmation email sent to customer:", email);

        return {
            statusCode: 200,
            headers: {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "OPTIONS,POST",
                "Access-Control-Allow-Headers": "Content-Type",
                "Access-Control-Allow-Credentials": true
            },
            body: JSON.stringify({ message: "Form submitted successfully" })
        };
    } catch (error) {
        console.error("Error processing request:", error);
        return {
            statusCode: 500,
            headers: {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "OPTIONS,POST",
                "Access-Control-Allow-Headers": "Content-Type",
                "Access-Control-Allow-Credentials": true
            },
            body: JSON.stringify({ error: "Internal server error" })
        };
    }
};

async function sendEmail(to, subject, body) {
    const params = {
        Destination: { ToAddresses: [to] },
        Message: {
            Body: { Text: { Data: body } },
            Subject: { Data: subject }
        },
        Source: ADMIN_EMAIL
    };
    await ses.sendEmail(params).promise();
}