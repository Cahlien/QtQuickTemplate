#!/usr/bin/env node
/**
 * extract-crowell-palette.js
 *
 * Extracts the color palette from https://www.crowell.dev by fetching
 * the site's CSS and parsing custom property definitions.
 *
 * Usage:  node tools/extract-crowell-palette.js
 * Output: tools/crowell-palette.json
 */

const fs = require("fs");
const path = require("path");

const SITE_URL = "https://www.crowell.dev";
const OUTPUT = path.join(__dirname, "crowell-palette.json");

async function fetchCSS() {
  const html = await fetch(SITE_URL).then((r) => r.text());
  const cssLinks = [...html.matchAll(/href="([^"]+\.css)"/g)].map((m) =>
    m[1].startsWith("http") ? m[1] : new URL(m[1], SITE_URL).href
  );

  let allCSS = "";
  // Also grab inline <style> blocks
  for (const match of html.matchAll(/<style[^>]*>([\s\S]*?)<\/style>/g)) {
    allCSS += match[1] + "\n";
  }
  for (const link of cssLinks) {
    try {
      allCSS += await fetch(link).then((r) => r.text()) + "\n";
    } catch (e) {
      console.warn(`Failed to fetch ${link}: ${e.message}`);
    }
  }
  return allCSS;
}

function extractPalette(css, name) {
  const palette = {};
  const re = new RegExp(`--color-${name}-(\\d+):\\s*([^;]+);`, "g");
  for (const m of css.matchAll(re)) {
    palette[m[1]] = m[2].trim();
  }
  return palette;
}

function relativeLuminance(hex) {
  const r = parseInt(hex.slice(1, 3), 16) / 255;
  const g = parseInt(hex.slice(3, 5), 16) / 255;
  const b = parseInt(hex.slice(5, 7), 16) / 255;
  const toLinear = (c) => (c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4);
  return 0.2126 * toLinear(r) + 0.7152 * toLinear(g) + 0.0722 * toLinear(b);
}

function contrastRatio(hex1, hex2) {
  const l1 = relativeLuminance(hex1);
  const l2 = relativeLuminance(hex2);
  const lighter = Math.max(l1, l2);
  const darker = Math.min(l1, l2);
  return +((lighter + 0.05) / (darker + 0.05)).toFixed(1);
}

function wcagLevel(ratio) {
  if (ratio >= 7) return "AAA";
  if (ratio >= 4.5) return "AA";
  if (ratio >= 3) return "AA-large";
  return "FAIL";
}

async function main() {
  console.log(`Fetching CSS from ${SITE_URL}...`);
  const css = await fetchCSS();

  const arcane = extractPalette(css, "arcane");
  const circuit = extractPalette(css, "circuit");

  console.log(`Found ${Object.keys(arcane).length} arcane shades`);
  console.log(`Found ${Object.keys(circuit).length} circuit shades`);

  const dark = {
    background: circuit["950"] || "#0a0a0c",
    surface: circuit["900"] || "#141416",
    surface2: circuit["800"] || "#1c1c1e",
    primary: arcane["400"] || "#40e0d0",
    secondary: arcane["500"] || "#2eb8a8",
    text: circuit["100"] || "#e4e4e7",
    mutedText: circuit["300"] || "#a1a1aa",
    border: circuit["700"] || "#27272a",
    onPrimary: arcane["950"] || "#081a19",
    success: "#4ade80",
    warning: "#facc15",
    danger: "#f87171",
    focusOutline: arcane["400"] || "#40e0d0",
    outline: circuit["600"] || "#3f3f46",
  };

  const light = {
    background: circuit["50"] || "#f4f4f5",
    surface: "#ffffff",
    surface2: circuit["100"] || "#e4e4e7",
    primary: arcane["500"] || "#2eb8a8",
    secondary: arcane["600"] || "#207068",
    text: circuit["900"] || "#141416",
    mutedText: circuit["500"] || "#52525b",
    border: circuit["200"] || "#d4d4d8",
    onPrimary: arcane["50"] || "#e6fffc",
    success: "#16a34a",
    warning: "#ca8a04",
    danger: "#dc2626",
    focusOutline: arcane["500"] || "#2eb8a8",
    outline: circuit["300"] || "#a1a1aa",
  };

  const checks = {
    textOnBackground: [dark.text, dark.background],
    mutedTextOnBackground: [dark.mutedText, dark.background],
    textOnSurface: [dark.text, dark.surface],
    primaryOnBackground: [dark.primary, dark.background],
    onPrimaryOnPrimary: [dark.onPrimary, dark.primary],
  };

  const validation = {};
  for (const [name, [fg, bg]] of Object.entries(checks)) {
    const ratio = contrastRatio(fg, bg);
    validation[name] = { ratio, pass: wcagLevel(ratio) };
    console.log(`  ${name}: ${ratio}:1 (${wcagLevel(ratio)})`);
  }

  const result = {
    source: SITE_URL,
    extractedAt: new Date().toISOString().slice(0, 10),
    palettes: { arcane, circuit },
    semantic: { dark, light },
    contrastValidation: { dark: validation },
  };

  fs.writeFileSync(OUTPUT, JSON.stringify(result, null, 2) + "\n");
  console.log(`\nPalette written to ${OUTPUT}`);
}

main().catch(console.error);
