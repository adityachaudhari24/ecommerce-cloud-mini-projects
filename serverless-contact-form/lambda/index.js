const AWS = require("aws-sdk");
const dynamoDB = new AWS.DynamoDB.DocumentClient();
const ses = new AWS.SES();

const TABLE_NAME = process.env.TABLE_NAME;
const ADMIN_EMAIL = process.env.SES_ADMIN_EMAIL;

exports.handler = async (event) => {
    try {
        const requestBody = JSON.parse(event.body);
        console.log("Received request body:", requestBody);

        const { name, email, message } = requestBody;
        if (!name || !email || !message) {
            return {
                statusCode: 400,
                body: JSON.stringify({ error: "Missing required fields: name, email, message" })
            };
        }

        // Save data to DynamoDB
        const putParams = {
            TableName: TABLE_NAME,
            Item: { email, name, message, timestamp: new Date().toISOString() }
        };
        await dynamoDB.put(putParams).promise();

        // Send email to Admin
        await sendEmail(ADMIN_EMAIL, "New Contact Form Submission", `New message from ${name} (${email}):\n\n${message}`);

        // Send confirmation email to customer
        await sendEmail(email, "Thank You for Contacting Us", `Hi ${name},\n\nThank you for reaching out. We have received your message and will get back to you soon.\n\nBest Regards,\nSupport Team`);

        return {
            statusCode: 200,
            body: JSON.stringify({ message: "Form submitted successfully" })
        };
    } catch (error) {
        console.error("Error processing request:", error);
        return {
            statusCode: 500,
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
