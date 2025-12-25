// To start the program
// Setup for the frontend
1. use "ipconfig" command in terminal to find your IPV4 IP address.
2. Replace the IP in the API_Base_URL in frontend folder's .env file with your IPV4 address. 
3. Navigate to frontend folder.
4. Use this command "flutter build apk --debug" to build the APK
5. Download and Install the APK in your mobile device.

//Setup for the backend
1. Navigate to backend folder.
2. Run this command "venv\Scripts\activate" in terminal to go inside virtual environment.
3. Run this command "uvicorn app.main:app --reload --host 0.0.0.0 --port 8000" in terminal to run the backend.

//Reminder
1. Make sure your mobile device for frontend and device that running the backend is connected to the same WIFI.
2. Backend must be running to use the system.