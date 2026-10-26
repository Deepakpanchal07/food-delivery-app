# 🍔 Foodie – Food Delivery App

A full-stack food delivery application built using **Flutter, Node.js, Express.js, and MongoDB**. The application allows users to explore restaurants, browse food menus, manage their cart, place orders, and access their account.



- GitHub: [GitHub repository link](https://github.com/Deepakpanchal07/food-delivery-app)
## 📸 Screenshots

### 🏠 Home Screen
<img width="950" alt="Foodie Home Screen" src="https://github.com/user-attachments/assets/3856d458-64ed-4765-b905-47989c6827da" />

### 🍽️ Restaurant Details & Food Menu
<img width="952" alt="Restaurant Details and Food Menu" src="https://github.com/user-attachments/assets/a0760488-f123-4c84-b1e8-e1266fe09527" />

### 👤 User Profile
<img width="950" alt="Foodie User Profile" src="https://github.com/user-attachments/assets/8c998572-e5bc-43ec-ae9a-8bb70c39ec89" />

### 🛠️ Admin Panel
<img width="943" alt="Foodie Admin Panel" src="https://github.com/user-attachments/assets/c8057930-bbdc-40ba-bbee-7bd6d310c292" />

### 🏪 Restaurant Management
<img width="948" alt="Restaurant Management" src="https://github.com/user-attachments/assets/4dae3835-c3ff-49a1-a061-8d79228a132a" />

### 🍕 Menu Management
<img width="946" alt="Menu Management" src="https://github.com/user-attachments/assets/1b86cd41-e810-463b-86fa-48fe910421ee" />

### order status
<img width="956" height="388" alt="Screenshot 2026-10-26 142916" src="https://github.com/user-attachments/assets/a0ffd7d0-65b1-4752-9704-f9805c3f2468" />

> Replace the screenshot filenames with your actual image filenames if they are different.

## ✨ Features

- 🏪 Restaurant listing and restaurant management
- 🍕 Food menu with categories and pricing
- 🛒 Shopping cart with item quantities
- 📦 Order placement and order history
- 🔐 User registration and login
- 👤 User profile management
- 🔑 Change password and forgot-password functionality
- 📧 Email and OTP verification functionality
- 💰 Delivery fee and order total calculation
- 🌐 REST API integration
- 📱 Cross-platform Flutter frontend
- 🎨 Clean UI with an orange-themed design

## 🛠️ Tech Stack

| Technology | Purpose |
|---|---|
| Flutter | Frontend UI |
| Dart | Application development |
| Node.js | Backend runtime |
| Express.js | REST API development |
| MongoDB | Database |
| Mongoose | MongoDB object modeling |
| JWT / Authentication middleware | Protected API access |
| Nodemailer | Email functionality |
| Git & GitHub | Version control |

## 📁 Project Structure

```text
food_delivery/
├── frontend/
│   ├── lib/
│   ├── android/
│   ├── web/
│   └── pubspec.yaml
│
├── backend/
│   ├── routes/
│   ├── models/
│   ├── middleware/
│   ├── .env
│   └── package.json
│
├── screenshots/
└── README.md
```

*Note: Adjust the folder structure above to match your actual repository.*

## ⚙️ Prerequisites

Install the following before running the application:

- Flutter SDK
- Dart SDK (included with Flutter)
- Node.js and npm
- MongoDB or a MongoDB connection URI
- Android Studio or Visual Studio Code
- Git

## 🚀 Installation & Setup

### 1. Clone the Repository

```bash
git clone YOUR_GITHUB_REPOSITORY_URL
cd food_delivery
```

Replace `YOUR_GITHUB_REPOSITORY_URL` with your GitHub repository URL.

### 2. Configure the Backend

```bash
cd backend
npm install
```

Create a `.env` file in the backend directory and configure your environment variables.

Example:

```env
PORT=5000
MONGODB_URI=your_mongodb_connection_string
JWT_SECRET=your_secret_key
```

Add your actual email configuration variables if required by your backend.

**Important:** Never commit your real passwords, API keys, email credentials, or JWT secrets to GitHub.

### 3. Start the Backend

```bash
npm start
```

If your project uses a different development script, use the command configured in `backend/package.json`.

Backend health check:

```text
http://localhost:5000/api/health
```

### 4. Configure the Flutter Frontend

Open a new terminal:

```bash
cd frontend
flutter pub get
```

Configure the backend base URL according to the device you are using:

- **Flutter Web:** `http://localhost:5000/api`
- **Android Emulator:** `http://10.0.2.2:5000/api`

For a physical Android device, configure your computer's reachable local IP address and ensure both devices can communicate over the network.

### 5. Run the Application

```bash
flutter run
```

Choose an available device, such as an Android emulator or Chrome.

## 🔌 API Overview

The backend provides REST API endpoints for the application's main functionality.

| Endpoint | Method | Purpose |
|---|---|---|
| `/api/health` | GET | Check backend health |
| `/api/restaurants` | GET | Retrieve restaurants |
| `/api/auth` | — | Authentication route prefix |
| `/api/menu` | — | Food menu route prefix |
| `/api/orders/my-orders` | GET | Retrieve the authenticated user's orders |
| `/api/orders` | POST | Place an order |

*Authentication and menu routes may contain additional endpoints. Refer to the backend route files for the complete API specification.*

## 🔒 Security

- Keep sensitive configuration in environment variables.
- Do not upload `.env` files to GitHub.
- Use appropriate authentication middleware for protected endpoints.
- Validate user input on the backend.
- Configure production secrets and database access securely.

## 🔮 Future Improvements

- Live order status tracking
- Online payment gateway integration
- Push notifications for order updates
- Restaurant search and filtering
- Ratings and reviews
- Production deployment and performance improvements

## 👨‍💻 Developer

**Deepak Panchal**

B.Tech in Computer Science and Engineering

- LinkedIn: [Deepak Panchal](https://www.linkedin.com/in/deepak-panchal-a0aa41362/)

## 📄 License

This project is available for learning and portfolio purposes. Add a suitable open-source license if you intend to distribute or reuse the project publicly.
