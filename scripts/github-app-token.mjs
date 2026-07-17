#!/usr/bin/env node

import { execFileSync } from "node:child_process";
import { createSign } from "node:crypto";

const githubApiVersion = "2022-11-28";

function fail(message) {
  console.error(`GitHub App 인증 오류: ${message}`);
  process.exit(1);
}

function run(command, args) {
  try {
    return execFileSync(command, args, { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] }).trim();
  } catch {
    fail(`${command} 실행에 실패했습니다.`);
  }
}

function getLocalGitConfig(key) {
  const value = run("git", ["config", "--local", "--get", key]);
  if (!value) {
    fail(`로컬 Git 설정 ${key}이 없습니다.`);
  }
  return value;
}

function toBase64Url(value) {
  return Buffer.from(value).toString("base64url");
}

function createAppJwt(appId, privateKey) {
  const issuedAt = Math.floor(Date.now() / 1000) - 60;
  const header = toBase64Url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const payload = toBase64Url(JSON.stringify({ iat: issuedAt, exp: issuedAt + 9 * 60, iss: appId }));
  const unsignedToken = `${header}.${payload}`;
  const signer = createSign("RSA-SHA256");

  signer.update(unsignedToken);
  signer.end();

  return `${unsignedToken}.${signer.sign(privateKey).toString("base64url")}`;
}

function readPrivateKey() {
  const storedKey = run("security", [
    "find-generic-password",
    "-a",
    "lifeos-github-app",
    "-s",
    "lifeos-github-app-private-key",
    "-w",
  ]);

  return /^[0-9a-f]+$/i.test(storedKey) && storedKey.length % 2 === 0
    ? Buffer.from(storedKey, "hex").toString("utf8")
    : storedKey;
}

async function githubRequest(path, token, method = "GET") {
  const response = await fetch(`https://api.github.com${path}`, {
    method,
    headers: {
      Accept: "application/vnd.github+json",
      Authorization: `Bearer ${token}`,
      "User-Agent": "lifeos-codex-automation",
      "X-GitHub-Api-Version": githubApiVersion,
    },
  });

  if (!response.ok) {
    fail(`GitHub API 요청이 실패했습니다 (${response.status}).`);
  }

  return response.json();
}

const appId = getLocalGitConfig("lifeos.githubAppId");
const privateKey = readPrivateKey();
const appJwt = createAppJwt(appId, privateKey);
const installations = await githubRequest("/app/installations", appJwt);

if (!Array.isArray(installations) || installations.length !== 1) {
  fail("자동화 App 설치를 하나만 찾을 수 있어야 합니다.");
}

const installation = installations[0];
const installationToken = await githubRequest(`/app/installations/${installation.id}/access_tokens`, appJwt, "POST");

if (process.argv.includes("--check")) {
  const repositories = await githubRequest("/installation/repositories", installationToken.token);
  console.log(
    JSON.stringify({
      installationAccount: installation.account.login,
      repositoryNames: repositories.repositories.map((repository) => repository.full_name),
    }),
  );
} else {
  process.stdout.write(installationToken.token);
}
