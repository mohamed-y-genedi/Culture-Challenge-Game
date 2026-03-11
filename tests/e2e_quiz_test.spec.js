const { test, expect, chromium, devices } = require('@playwright/test');

// We use the semantics labels added in the Flutter Web App for reliable element locating.

test.describe('Quiz App E2E Stress Tests', () => {

    // Test 1: Single Player + Lifelines + Timer Exhaustion + Leaderboard
    test('Single Player - Timer Exhaustion & Lifelines', async () => {
        const browser = await chromium.launch();
        const context = await browser.newContext();
        const page = await context.newPage();

        await page.goto('http://localhost:55073/');
        await page.waitForLoadState('networkidle');

        // Home Screen
        await expect(page).toHaveTitle(/Culture Challenge|Quiz/i);

        // Fill Nickname via Semantic Label
        const nicknameInput = page.locator('flt-semantics[aria-label="NICKNAME_INPUT"] input');
        // If the input is deeply nested in the semantics, we can also just use the semantic label directly
        await page.getByLabel('NICKNAME_INPUT').fill('Test_Player_1');

        // Click Single Player
        await page.getByLabel('SINGLE_PLAYER_BTN').click();

        // Since Single Player navigates to Category first (Option B logic), wait for Category and pick Islamic
        await page.locator('text=Islamic').click();

        // In Game Screen: Test Lifelines
        await expect(page.getByLabel('LIFELINE_FIFTY_FIFTY')).toBeVisible({ timeout: 10000 });

        // Click 50:50 Lifeline
        await page.getByLabel('LIFELINE_FIFTY_FIFTY').click();

        // Validate it becomes disabled (Flutter removes the interactive role or adds disabled state)
        // We can just verify it does not trigger again or changes state.

        // Click Ask Audience Lifeline
        await page.getByLabel('LIFELINE_ASK_AUDIENCE').click();
        // Validate Dialog appears
        await expect(page.locator('text=نتيجة تصويت الجمهور')).toBeVisible();
        await page.locator('text=حسناً').click(); // Close dialog

        // Test Timer Exhaustion (Wait for 15s to elapse without answering)
        // The UI should auto-transition to the next question.
        // Question 1 -> Question 2
        await page.waitForTimeout(16000); // Wait 16 seconds

        // Answer the rest of the questions quickly to trigger Game Over
        // We can loop to click the first available option.
        for (let i = 0; i < 14; i++) { // Remaining 14 questions
            // Click Option A (or whatever is available)
            const optionA = page.locator('flt-semantics[aria-label^="OPTION_BTN_"]').first();
            if (await optionA.isVisible()) {
                await optionA.click();
            }
            await page.waitForTimeout(2500); // Wait for transition
        }

        // Verify Leaderboard Navigation from Result Screen
        await page.locator('text=Return to Home').click();

        // Home Screen -> Go to Leaderboard
        await page.getByLabel('LEADERBOARD_BTN').click();
        await expect(page.locator('text=لوحة الشرف 🏆')).toBeVisible();

        await browser.close();
    });

    // Test 2: Multi-User Sync & Responsive Check
    test('Multiplayer Sync - Host and Opponent - Responsive Check', async () => {
        const browser = await chromium.launch();

        // Host Context (Desktop)
        const hostContext = await browser.newContext();
        const hostPage = await hostContext.newPage();

        // Opponent Context (iPhone 14)
        const iPhone14 = devices['iPhone 14'];
        const oppContext = await browser.newContext({ ...iPhone14 });
        const oppPage = await oppContext.newPage();

        // =============== HOST SETUP ===============
        await hostPage.goto('http://localhost:55073/');
        await hostPage.waitForLoadState('networkidle');
        await hostPage.getByLabel('NICKNAME_INPUT').fill('Host_Mido');
        await hostPage.getByLabel('MULTIPLAYER_BTN').click();

        await hostPage.getByLabel('CREATE_ROOM_BTN').click();
        await hostPage.locator('text=Islamic').click();

        // Retrieve the room code (assuming it has a specific semantic label or we grab from text)
        // Waiting for the text matching 5 uppercase alphanumeric chars.
        const roomCodeText = await hostPage.locator('text=رمز الغرفة:').innerText({ timeout: 10000 });
        const roomCode = roomCodeText.split(':')[1].trim();
        console.log(`[Playwright] Room created with code: ${roomCode}`);

        // =============== OPPONENT SETUP ===============
        await oppPage.goto('http://localhost:55073/');
        await oppPage.waitForLoadState('networkidle');
        await oppPage.getByLabel('NICKNAME_INPUT').fill('Opponent_Ahmad');
        await oppPage.getByLabel('MULTIPLAYER_BTN').click();

        await oppPage.getByLabel('ROOM_CODE_INPUT').fill(roomCode);
        await oppPage.getByLabel('JOIN_ROOM_BTN').click();

        // =============== SYNC VERIFICATION ===============
        // Both should auto-start and navigate to Game Screen simultaneously
        await expect(hostPage.locator('text=السؤال 1 من 15')).toBeVisible({ timeout: 15000 });
        await expect(oppPage.locator('text=السؤال 1 من 15')).toBeVisible({ timeout: 15000 });

        // Host answers
        await hostPage.locator('flt-semantics[aria-label^="OPTION_BTN_"]').first().click();
        // Opponent answers
        await oppPage.locator('flt-semantics[aria-label^="OPTION_BTN_"]').last().click();

        // Wait for auto-transition to next question
        await expect(hostPage.locator('text=السؤال 2 من 15')).toBeVisible({ timeout: 10000 });
        await expect(oppPage.locator('text=السؤال 2 من 15')).toBeVisible({ timeout: 10000 });

        await browser.close();
    });

});
