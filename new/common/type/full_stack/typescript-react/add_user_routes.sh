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
import React from "react";

const Login = () => {
  return <p>Login</p>;
};

export default Login;
EOF

git add $FILE

FILE=src/components/Logout.tsx

cat > $FILE << EOF
import React from "react";

const Logout = () => {
  return <p>Logout</p>;
};

export default Logout;
EOF

git add $FILE

FILE=src/components/Profile.tsx

cat > $FILE << EOF
import React from "react";

const Profile = () => {
  return <p>Profile</p>;
};

export default Profile;
EOF

git add $FILE

FILE=src/components/Register.tsx

cat > $FILE << EOF
import React from "react";

const Register = () => {
  return <p>Register</p>;
};

export default Register;
EOF

git add $FILE

FILE=src/components/ResetPassword.tsx

cat > $FILE << EOF
import React from "react";

const ResetPassword = () => {
  return <p>ResetPassword</p>;
};

export default ResetPassword;
EOF

git add $FILE

FILE=src/components/VerifyEmail.tsx

cat > $FILE << EOF
import React from "react";

const VerifyEmail = () => {
  return <p>VerifyEmail</p>;
};

export default VerifyEmail;
EOF

git add $FILE

FILE=src/components/VerifyReset.tsx

cat > $FILE << EOF
import React from "react";

const VerifyReset = () => {
  return <p>VerifyReset</p>;
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
