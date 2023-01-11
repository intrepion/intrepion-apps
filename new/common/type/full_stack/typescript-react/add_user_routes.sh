#!/bin/bash

SCRIPT=$0
REPOSITORY=$1

echo " - Running $SCRIPT $REPOSITORY"

if [ $# -ne 1 ]; then
  echo "usage: $SCRIPT <REPOSITORY>"
  exit 1
fi

pushd .

cd $REPOSITORY
pwd

npm install react-router-dom

git add --all
git commit --message "npm install react-router-dom"

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
            <Link to="/Register">Register</Link>
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

mkdir -p src/components

FILE=src/components/Home.tsx
cat > $FILE << EOF
import React from "react";

const Home = () => {
  return <h1>Home</h1>;
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
          navigate("/");
        } else if (responseJson.error) {
          console.error(responseJson.error);
        }
        setLoadingLogin(false);
      })
      .catch((error) => {
        console.error(error);
      });
  };

  const handleChangePassword = (event: React.ChangeEvent<HTMLInputElement>) => {
    setPassword(event.target.value);
  };

  const handleChangeUsername = (event: React.ChangeEvent<HTMLInputElement>) => {
    setUsername(event.target.value);
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
import React, { useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { v4 } from "uuid";

const SERVER_URL = process.env.REACT_APP_SERVER_URL ?? "http://localhost:3000";

const Logout: React.FC = () => {
  const navigate = useNavigate();

  useEffect(() => {
    fetch(SERVER_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        id: v4(),
        jsonrpc: "2.0",
        method: "logout",
      }),
    })
      .then((response) => response.json())
      .then((responseJson) => {
        if (responseJson.result) {
          navigate("/");
        } else if (responseJson.error) {
          console.error(responseJson.error);
        }
      })
      .catch((error) => {
        console.error(error);
      });
  });

  return (
    <div>
      <h1>Logout</h1>
    </div>
  );
};

export default Logout;
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

  const handleChangeConfirm = (event: React.ChangeEvent<HTMLInputElement>) => {
    setConfirm(event.target.value);
  };

  const handleChangeEmail = (event: React.ChangeEvent<HTMLInputElement>) => {
    setEmail(event.target.value);
  };

  const handleChangePassword = (event: React.ChangeEvent<HTMLInputElement>) => {
    setPassword(event.target.value);
  };

  const handleChangeUsername = (event: React.ChangeEvent<HTMLInputElement>) => {
    setUsername(event.target.value);
  };

  return (
    <div>
      <h1>Register</h1>
      <label htmlFor="username">
        Username:{" "}
        <input
          id="username"
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

FILE=src/index.tsx
cat > $FILE << EOF
import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import reportWebVitals from "./reportWebVitals";
import { BrowserRouter } from "react-router-dom";

const root = ReactDOM.createRoot(
  document.getElementById("root") as HTMLElement
);
root.render(
  <React.StrictMode>
    <BrowserRouter>
      <App />
    </BrowserRouter>
  </React.StrictMode>
);

reportWebVitals();
EOF
git add $FILE

FILE=src/Main.tsx
cat > $FILE << EOF
import React from "react";
import { Routes, Route } from "react-router-dom";
import Home from "./components/Home";
import Login from "./components/Login";
import Logout from "./components/Logout";
import Register from "./components/Register";

const Loading = () => <p>Loading ...</p>;

const Main = () => {
  return (
    <React.Suspense fallback={<Loading />}>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/Login" element={<Login />} />
        <Route path="/Logout" element={<Logout />} />
        <Route path="/Register" element={<Register />} />
      </Routes>
    </React.Suspense>
  );
};

export default Main;
EOF
git add $FILE
git commit --message "Added user routes."

npx prettier --write .
git add --all
git commit --message "npx prettier --write ."

popd

echo " - Completed $SCRIPT $REPOSITORY"
