import 'package:flutter/material.dart';

// ── Основная палитра Newgrounds ──────────────────────────────────────────────
const Color ngOrange      = Color(0xFFFF6600); // основной акцент
const Color ngOrangeLight = Color(0xFFFF8833); // hover / secondary accent
const Color ngYellow      = Color(0xFFFFCC00); // NG «звёздный» жёлтый

// ── Фоны ─────────────────────────────────────────────────────────────────────
const Color ngBgDeep     = Color(0xFF000000); // чёрная шапка / топбар
const Color ngBgDark     = Color(0xFF111111); // основной фон
const Color ngBgCard     = Color(0xFF1A1A1A); // карточка трека
const Color ngBgElevated = Color(0xFF222222); // слегка приподнятый слой

// ── Границы ──────────────────────────────────────────────────────────────────
const Color ngBorder      = Color(0xFF333333);
const Color ngBorderLight = Color(0xFF444444);

// ── Текст ────────────────────────────────────────────────────────────────────
const Color ngTextPrimary = Color(0xFFFFFFFF);
const Color ngTextMuted   = Color(0xFF888888);
const Color ngTextDim     = Color(0xFF555555);

// ── Прочее ───────────────────────────────────────────────────────────────────
const Color ngRed   = Color(0xFFCC0000); // ошибка / 18+
const Color ngGreen = Color(0xFF33CC33); // успех / скачано

// ── ThemeData ────────────────────────────────────────────────────────────────
final ThemeData ngTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: ngBgDark,
  colorScheme: const ColorScheme.dark(
    primary: ngOrange,
    secondary: ngOrangeLight,
    surface: ngBgCard,
    error: ngRed,
    onPrimary: Colors.black,
    onSecondary: Colors.black,
    onSurface: ngTextPrimary,
  ),
  dividerColor: ngBorder,
  splashColor: ngOrange.withAlpha(30),
  highlightColor: ngOrange.withAlpha(20),
);
