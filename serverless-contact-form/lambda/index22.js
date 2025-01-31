exports.handler = async (event) => {
    console.log("Received event:", JSON.stringify(event, null, 2));

    let requestBody;
    try {
        requestBody = JSON.parse(event.body);
        console.log("Request body (JSON):", requestBody);
    } catch (error) {
        requestBody = event.body;
        console.log("Request body (non-JSON):", requestBody);
    }

    return {
        statusCode: 200,
        body: JSON.stringify({
            message: 'Hello, world!',
            receivedData: requestBody
        }),
    };
};