#!/usr/bin/env node
/**
 * validate-contrast.js
 *
 * Reads tools/crowell-palette.json and validates contrast ratios
 * for all key foreground/background combinations.
 *
 * Usage: node tools/validate-contrast.js
 */

const fs = require("fs");
const path = require("path");

const palette = JSON.parse(
  fs.readFileSync(path.join(__dirname, "crowell-palette.json"), "utf8")
);

function relativeLuminance(hex) {
  const r = parseInt(hex.slice(1, 3), 16) / 255;
  const g = parseInt(hex.slice(3, 5), 16) / 255;
  const b = parseInt(hex.slice(5, 7), 16) / 255;
  const toLinear = (c) =>
    c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
  return 0.2126 * toLinear(r) + 0.7152 * toLinear(g) + 0.0722 * toLinear(b);
}

function contrastRatio(hex1, hex2) {
  const l1 = relativeLuminance(hex1);
  const l2 = relativeLuminance(hex2);
  const lighter = Math.max(l1, l2);
  const darker = Math.min(l1, l2);
  return +((lighter + 0.05) / (darker + 0.05)).toFixed(1);
}

function check(label, fg, bg, minRatio = 4.5) {
  const ratio = contrastRatio(fg, bg);
  const pass = ratio >= minRatio;
  const level = ratio >= 7 ? "AAA" : ratio >= 4.5 ? "AA" : "FAIL";
  const icon = pass ? "✅" : "❌";
  console.log(
    `${icon} ${label.padEnd(35)} ${ratio.toFixed(1).padStart(5)}:1  ${level}  (${fg} on ${bg})`
  );
  return pass;
}

console.log("=== Dark Mode Contrast Validation ===\n");
const d = palette.semantic.dark;
let allPass = true;
allPass &= check("text on background", d.text, d.background);
allPass &= check("text on surface", d.text, d.surface);
allPass &= check("mutedText on background", d.mutedText, d.background);
allPass &= check("mutedText on surface", d.mutedText, d.surface);
allPass &= check("primary on background", d.primary, d.background);
allPass &= check("onPrimary on primary", d.onPrimary, d.primary);
allPass &= check("success on background", d.success, d.background);
allPass &= check("warning on background", d.warning, d.background);
allPass &= check("danger on background", d.danger, d.background);

console.log("\n=== Light Mode Contrast Validation ===\n");
const l = palette.semantic.light;
allPass &= check("text on background", l.text, l.background);
allPass &= check("text on surface", l.text, l.surface);
allPass &= check("mutedText on background", l.mutedText, l.background);
allPass &= check("mutedText on surface", l.mutedText, l.surface);
allPass &= check("primary on background", l.primary, l.background);
allPass &= check("onPrimary on primary", l.onPrimary, l.primary);

console.log(
  `\n${allPass ? "✅ All checks passed" : "❌ Some checks failed — review derived tokens"}`
);
process.exit(allPass ? 0 : 1);
