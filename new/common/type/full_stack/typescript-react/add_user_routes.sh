#!/bin/bash

SCRIPT=$0
REPOSITORY=$1

echo "Running $SCRIPT $REPOSITORY"

pushd .

cd $REPOSITORY
pwd

npm install react-router-dom

git add --all
git commit --message "npm install react-router-dom"

mkdir -p src/components

FILE=src/components/Home.tsx

cat > $FILE << EOF
import React from "react";

const Home = () => {
  return <p>Home</p>;
};

export default Home;
EOF

git add $FILE

FILE=src/components/Login.tsx

cat > $FILE << EOF
import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { v4 } from "uuid";

const SERVER_URL = process.env.REACT_APP_SERVER_URL ?? "http://localhost:3000";

const Login = () => {
  const [loadingLogin, setLoadingLogin] = useState(false);
  const [password, setPassword] = useState("");
  const [username, setUsername] = useState("");
  const navigate = useNavigate();

  const callLogin = (event: React.MouseEvent<HTMLElement>) => {
    event.preventDefault();
    setLoadingLogin(true);
    fetch(SERVER_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        id: v4(),
        jsonrpc: "2.0",
        method: "login",
        params: { password, username },
      }),
    })
      .then((response) => response.json())
      .then((responseJson) => {
        if (responseJson.result) {
          navigate("/Login");
        } else if (responseJson.error) {
          console.error(responseJson.error);
        }
        setLoadingLogin(false);
      })
      .catch((error) => {
        console.error(error);
      });
  };

  const handleChangeUsername = (event: React.ChangeEvent<HTMLInputElement>) => {
    setUsername(event.target.value);
  };

  const handleChangePassword = (event: React.ChangeEvent<HTMLInputElement>) => {
    setPassword(event.target.value);
  };

  return (
    <div>
      <h1>Login</h1>
      <label htmlFor="username">
        Username:{" "}
        <input
          id="name"
          onChange={handleChangeUsername}
          type="text"
          value={username}
        />
      </label>
      <label htmlFor="password">
        Password:{" "}
        <input
          id="password"
          onChange={handleChangePassword}
          type="password"
          value={password}
        />
      </label>
      <button disabled={loadingLogin} onClick={callLogin}>
        Login
      </button>
    </div>
  );
};

export default Login;
EOF

git add $FILE

FILE=src/components/Logout.tsx

cat > $FILE << EOF
import React from "react";
import { Navigate } from "react-router-dom";

const Logout = () => {
  return <Navigate to="/" />;
};

export default Logout;
EOF

git add $FILE

FILE=src/components/Profile.tsx

cat > $FILE << EOF
import React from "react";

const Profile = () => {
  return <h1>Profile</h1>;
};

export default Profile;
EOF

git add $FILE

FILE=src/components/Register.tsx

cat > $FILE << EOF
import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { v4 } from "uuid";

const SERVER_URL = process.env.REACT_APP_SERVER_URL ?? "http://localhost:3000";

const Register = () => {
  const [confirm, setConfirm] = useState("");
  const [email, setEmail] = useState("");
  const [loadingRegister, setLoadingRegister] = useState(false);
  const [password, setPassword] = useState("");
  const [username, setUsername] = useState("");
  const navigate = useNavigate();

  const callRegister = (event: React.MouseEvent<HTMLElement>) => {
    event.preventDefault();
    setLoadingRegister(true);
    fetch(SERVER_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        id: v4(),
        jsonrpc: "2.0",
        method: "register",
        params: { confirm, email, password, username },
      }),
    })
      .then((response) => response.json())
      .then((responseJson) => {
        if (responseJson.result) {
          navigate("/Login");
        } else if (responseJson.error) {
          console.error(responseJson.error);
        }
        setLoadingRegister(false);
      })
      .catch((error) => {
        console.error(error);
      });
  };

  const handleChangeUsername = (event: React.ChangeEvent<HTMLInputElement>) => {
    setUsername(event.target.value);
  };

  const handleChangeEmail = (event: React.ChangeEvent<HTMLInputElement>) => {
    setEmail(event.target.value);
  };

  const handleChangePassword = (event: React.ChangeEvent<HTMLInputElement>) => {
    setPassword(event.target.value);
  };

  const handleChangeConfirm = (event: React.ChangeEvent<HTMLInputElement>) => {
    setConfirm(event.target.value);
  };

  return (
    <div>
      <h1>Register</h1>
      <label htmlFor="username">
        Username:{" "}
        <input
          id="name"
          onChange={handleChangeUsername}
          type="text"
          value={username}
        />
      </label>
      <label htmlFor="email">
        Email:{" "}
        <input
          id="email"
          onChange={handleChangeEmail}
          type="email"
          value={email}
        />
      </label>
      <label htmlFor="password">
        Password:{" "}
        <input
          id="password"
          onChange={handleChangePassword}
          type="password"
          value={password}
        />
      </label>
      <label htmlFor="confirm">
        Confirm:{" "}
        <input
          id="confirm"
          onChange={handleChangeConfirm}
          type="password"
          value={confirm}
        />
      </label>
      <button disabled={loadingRegister} onClick={callRegister}>
        Register
      </button>
    </div>
  );
};

export default Register;
EOF

git add $FILE

FILE=src/components/ResetPassword.tsx

cat > $FILE << EOF
import React from "react";

const ResetPassword = () => {
  return <h1>ResetPassword</h1>;
};

export default ResetPassword;
EOF

git add $FILE

FILE=src/components/VerifyEmail.tsx

cat > $FILE << EOF
import React from "react";

const VerifyEmail = () => {
  return <h1>VerifyEmail</h1>;
};

export default VerifyEmail;
EOF

git add $FILE

FILE=src/components/VerifyReset.tsx

cat > $FILE << EOF
import React from "react";

const VerifyReset = () => {
  return <h1>VerifyReset</h1>;
};

export default VerifyReset;
EOF

git add $FILE

FILE=src/index.tsx

sed -i 's/    <App \/>/    <BrowserRouter>\
      <App \/>\
    <\/BrowserRouter>/' $FILE
sed -i '/import reportWebVitals from "\.\/reportWebVitals";/a\
import { BrowserRouter } from "react-router-dom";' $FILE

git add $FILE

FILE=src/Main.tsx

cat > $FILE << EOF
import React from "react";
import { Routes, Route } from "react-router-dom";
import Home from "./components/Home";
import Login from "./components/Login";
import Logout from "./components/Logout";
import Profile from "./components/Profile";
import Register from "./components/Register";
import ResetPassword from "./components/ResetPassword";
import VerifyEmail from "./components/VerifyEmail";
import VerifyReset from "./components/VerifyReset";

const Loading = () => <p>Loading ...</p>;

const Main = () => {
  return (
    <React.Suspense fallback={<Loading />}>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/Login" element={<Login />} />
        <Route path="/Logout" element={<Logout />} />
        <Route path="/Profile" element={<Profile />} />
        <Route path="/Register" element={<Register />} />
        <Route path="/ResetPassword" element={<ResetPassword />} />
        <Route path="/VerifyEmail" element={<VerifyEmail />} />
        <Route path="/VerifyReset" element={<VerifyReset />} />
      </Routes>
    </React.Suspense>
  );
};

export default Main;
EOF

git add $FILE

FILE=src/App.tsx

cat > $FILE << EOF
import React from "react";
import { Link } from "react-router-dom";
import Main from "./Main";

function App() {
  return (
    <>
      <div>
        <ul>
          <li>
            <Link to="/">Home</Link>
          </li>
          <li>
            <Link to="/Login">Login</Link>
          </li>
          <li>
            <Link to="/Logout">Logout</Link>
          </li>
          <li>
            <Link to="/Profile">Profile</Link>
          </li>
          <li>
            <Link to="/Register">Register</Link>
          </li>
          <li>
            <Link to="/ResetPassword">ResetPassword</Link>
          </li>
          <li>
            <Link to="/VerifyEmail">VerifyEmail</Link>
          </li>
          <li>
            <Link to="/VerifyReset">VerifyReset</Link>
          </li>
        </ul>
        <hr />
        <Main />
      </div>
    </>
  );
}

export default App;
EOF

git add $FILE

git commit --message "Added user routes."

npx prettier --write .
git add --all
git commit --message "npx prettier --write ."

popd

echo "Completed $SCRIPT $REPOSITORY"
