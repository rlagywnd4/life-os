import { expect, test } from "@playwright/test";

test("landing page exposes auth CTAs and product principles", async ({ page }) => {
  await page.goto("/");
  await expect(page.getByRole("heading", { name: /하고 싶은 일을/ })).toBeVisible();
  await expect(page.getByRole("link", { name: /무료로 시작하기/ })).toBeVisible();
  await expect(page.getByText("휴식도 계획")).toBeVisible();
});

test("login page renders email password form", async ({ page }) => {
  await page.goto("/login");
  await expect(page.getByRole("heading", { name: "로그인" })).toBeVisible();
  await expect(page.getByLabel("이메일")).toBeVisible();
  await expect(page.getByLabel("비밀번호")).toBeVisible();
});
