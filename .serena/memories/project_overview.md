# SplitMates Project Overview

## Purpose
SplitMates is a Flutter application for bill splitting in a simple, single-page interface. It supports adding items, discounts, receipt scanning (OCR), and calculating costs per person. The app is designed to be easy, fast, and clean with UX that teaches through gestures without tutorials.

## Core Features
- **Add items manually**: Name + price + select multiple owners
- **Add items from receipt (OCR)**: Select image, crop, extract items with "name + number"
- **Auto emoji assignment**: From item names (user editable)
- **Item discounts**: Via swipe right gesture
- **Global bill discount**: Amount or percentage, split equally or proportionally
- **Person management**: Add people with names and avatars (emoji or images), persistent storage
- **Bill summary**: Shows amount each person pays and discount received
- **Export results**: Save summary as PNG image

## Target Language/Locale
- Thai language interface
- Thai Baht (฿) currency
- All UI text and messages in Thai

## Key UX Interactions
- Swipe right (left→right): Add item discount
- Swipe left (right→left): Delete item
- Animation hint on first item to show swipe gestures
- Single-page design with no complex navigation