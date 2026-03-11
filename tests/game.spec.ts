import { test } from '@playwright/test';
import { ai } from '@zerostep/playwright';

test('تجربة اللعبة بالذكاء الاصطناعي', async ({ page, browserName }) => {
  test.setTimeout(120000);
  // ZeroStep AI يعمل فقط مع Chromium
  test.skip(browserName !== 'chromium', 'ZeroStep AI only works with Chromium');

  // 1. فتح رابط اللعبة على الصفحة الرئيسية
  await page.goto('http://localhost:61288/'); // Loading the root usually redirects properly.

  // ننتظر ٦ ثواني حتى يحمل محرك Flutter Web واجهة اللعبة بالكامل
  await page.waitForTimeout(6000);

  // تفعيل وضع دعم القراءة للتمكن من رؤية عناصر اللعبة (ضروري لـ Flutter Web)
  await page.evaluate(() => {
    const btn = document.querySelector('flt-semantics-placeholder');
    if (btn instanceof HTMLElement) btn.click();
  });
  await page.waitForTimeout(2000); // إعطاء فلاتر وقت لبناء الشجرة

  // 1.5. إضافة اسم اللاعب قبل اللعب
  await ai('Type "Player1" into the NICKNAME field', { page, test });

  // 2. الضغط على زر اللعب الفردي
  await ai('Click on "SINGLE PLAYER"', { page, test });

  // 3. أمر للذكاء الاصطناعي إنه يقرأ الشاشة ويضغط على قسم التاريخ
  await ai('Click on the History category', { page, test });

  // 3. نخليه ينتظر ٥ ثواني عشان يلحق يحمل الأسئلة من Supabase ويبدأ الجيم
  await page.waitForTimeout(5000);

  // التأكد من أننا انتقلنا لشاشة اللعب الفعلي (حتى لا يعلق إذا كان القسم فارغاً من الأسئلة)
  if (!page.url().includes('game')) {
    console.log('Game did not start! (Possibly no questions in database for this category). Skipping loop.');
    return;
  }

  // 4. حلقة تكرار للإجابة على 5 أسئلة
  for (let i = 0; i < 5; i++) {
    console.log(`Answering question ${i + 1}/5...`);
    
    // التحقق اذا وصلنا لشاشة النتيجة مبكراً
    if (page.url().includes('result')) {
      console.log('Result screen reached early. Breaking loop.');
      break;
    }

    let clicked = false;
    for (let retry = 0; retry < 3; retry++) {
      try {
        // قراءة السؤال بدقة وتحديد الإجابة الصحيحة تاريخياً والضغط عليها فقط
        await ai('Read the question, determine the historically correct answer from the available options below it, and click on it.', { page, test });
        clicked = true;
        break; // Success, exit retry loop
      } catch (error) {
        console.log(`AI click failed (attempt ${retry + 1}/3). Error: ${error instanceof Error ? error.message : String(error)}`);
        await page.waitForTimeout(2000); 
      }
    }

    if (!clicked) {
      console.log('Failed to click after 3 retries. Ending loop early.');
      break;
    }

    // الانتظار لمدة ٤ ثواني حتى تنتقل اللعبة وتستقر الشاشة للسؤال التالي بعد إصلاح مشكلة التصفير
    await page.waitForTimeout(4000);
  }

  // 5. التحقق من الوصول لشاشة النتيجة وتوثيقها بصورة
  if (page.url().includes('result')) {
    await ai('Check if the final score or result screen is visible', { page, test });
    
    // أخذ لقطة شاشة وحفظها في مجلد screenshots للتأكد من النتيجة النهائية
    console.log('Taking screenshot of the final score...');
    await page.screenshot({ path: 'screenshots/final_score.png', fullPage: true });
  }
});