<html>
<head>
    <title>Contact Us</title>
    <script>
        async function handleSubmit(event) {
            event.preventDefault();

            const form = event.target;
            const formData = new FormData(form);
            const data = {};

            formData.forEach((value, key) => {
                data[key] = value;
            });

            const response = await fetch(form.action, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(data),
            });

            if (response.ok) {
                alert('Form submitted successfully!');
            } else {
                alert('Failed to submit the form.');
            }
        }
    </script>
</head>
<body>
<h1>Contact Us</h1>
<form name="contactForm" action="${api_gateway_stage_invoke_url}" onsubmit="handleSubmit(event)" method="post">
    <label for="name">Name:</label><br>
    <input type="text" id="name" name="name"><br>
    <label for="email">Email:</label><br>
    <input type="text" id="email" name="email"><br>
    <label for="message">Message:</label><br>
    <textarea id="message" name="message"></textarea><br>
    <input type="submit" value="Submit">
</form>
</body>
</html>
