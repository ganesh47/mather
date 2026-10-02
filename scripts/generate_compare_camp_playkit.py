#!/usr/bin/env python3
"""Build the printable companion from the same artwork used by Compare Camp."""
from pathlib import Path
from reportlab.pdfgen import canvas
from reportlab.lib.colors import HexColor, white
from reportlab.lib.utils import ImageReader
from reportlab.lib.pagesizes import A4
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "output/pdf/compare-camp-family-play-kit.pdf"
ASSETS = ROOT / "App/Assets.xcassets"
W, H = A4
NAVY, TEAL, GOLD = map(HexColor, ["#142B3B", "#1C686D", "#E8B853"])
PALE = HexColor("#F0F6F3")


def art(c, name, x, y, width, height):
    # Size the PDF's embedded copy for this print slot; preserve full app originals.
    with Image.open(ASSETS / f"{name}.imageset/{name}.png") as source:
        embedded = source.copy()
    embedded.thumbnail((round(width * 3), round(height * 3)), Image.Resampling.LANCZOS)
    c.drawImage(ImageReader(embedded),
                x, y, width, height, preserveAspectRatio=True, anchor="c", mask="auto")


def text(c, value, x, y, size=11, color=NAVY, bold=False):
    c.setFillColor(color)
    c.setFont("Helvetica-Bold" if bold else "Helvetica", size)
    c.drawString(x, y, value)


def paragraph(c, value, x, y, width, size=11, leading=17):
    words, line = value.split(), ""
    for word in words:
        trial = (line + " " + word).strip()
        if c.stringWidth(trial, "Helvetica", size) > width and line:
            text(c, line, x, y, size)
            y -= leading
            line = word
        else:
            line = trial
    if line:
        text(c, line, x, y, size)
        y -= leading
    return y


def page(c, title, subtitle, number):
    c.setFillColor(white)
    c.rect(0, 0, W, H, fill=1, stroke=0)
    text(c, "COMPARE CAMP / FAMILY FIELD GUIDE", 38, H - 36, 9, TEAL, True)
    text(c, title, 38, H - 77, 26, NAVY, True)
    paragraph(c, subtitle, 38, H - 101, W - 76, 10, 14)
    c.setStrokeColor(HexColor("#C9DBD5"))
    c.line(38, 39, W - 38, 39)
    text(c, "No timer. Take turns. Explore together.", 38, 25, 9, TEAL)
    text(c, str(number), W - 46, 25, 9, TEAL)


def mission(c, title, prompt, build, notice, x, y, width, height, icon):
    c.setFillColor(PALE)
    c.roundRect(x, y, width, height, 14, fill=1, stroke=0)
    art(c, icon, x + width - 63, y + height - 68, 48, 48)
    text(c, title, x + 16, y + height - 31, 16, TEAL, True)
    yy = paragraph(c, prompt, x + 16, y + height - 79, width - 32, 12, 18)
    text(c, "MAKE IT", x + 16, yy - 9, 8, TEAL, True)
    yy = paragraph(c, build, x + 16, yy - 27, width - 32, 10, 15)
    text(c, "WONDER TOGETHER", x + 16, yy - 10, 8, TEAL, True)
    paragraph(c, notice, x + 16, yy - 28, width - 32, 10, 15)


def main():
    OUT.parent.mkdir(parents=True, exist_ok=True)
    c = canvas.Canvas(str(OUT), pagesize=A4)
    c.setTitle("Compare Camp - Family Play Kit")
    c.setAuthor("Mather")
    page(c, "A little camp. Big discoveries.",
         "A printable companion to the 24 camps and six learning trails in Mather TV.", 1)
    art(c, "CompareCampGuide", 350, 545, 175, 175)
    y = H - 166
    for title, body in [
        ("1 / Choose a world", "Apples, animals, ocean creatures, birds, planets and vehicles all become things to compare. Let your child pick a camp and a comfortable group size."),
        ("2 / Build, see, then explain", "Move real objects first. Line them up in pairs. Only then introduce the numbers and the signs. Ask what changed when you added or removed one object."),
        ("3 / Help without rushing", "Try: Can each one find a partner? Count by touching one object at a time. A mistake is an invitation to rearrange, count and try again."),
        ("4 / Finish with a new setting", "Use a different object or arrangement for the last mission. The TV passport records explored camps; a sticker celebrates an adventure, rather than certifying mastery."),
    ]:
        text(c, title, 38, y, 15, TEAL, True)
        y = paragraph(c, body, 38, y - 24, 305 if y > 540 else W - 76, 11, 17) - 23
    text(c, "PACK YOUR KIT", 38, 205, 11, TEAL, True)
    paragraph(c, "Use the eight mission cards on pages 2-3, the mat on page 4, tokens on page 5 and your camp passport on page 6. Print two token sheets for large groups of the same object. Buttons, blocks or pebbles work too.", 38, 180, W - 76, 11, 17)
    paragraph(c, "A grown-up reads the prompts. In the app, spoken guidance and the remote do the work. Start with groups up to five, and grow when your child wants a new challenge.", 38, 105, W - 76, 10, 15)
    c.showPage()

    missions = [
        ("More at the orchard", "Which group has more apples?", "Put 3 apples on the left and 5 on the right.", "Pair them. Two on the right have no partner. Swap sides and ask again.", "CompareCampApple"),
        ("Fewer flowers", "Which garden has fewer flowers?", "Put 6 flowers on the left and 4 on the right.", "Count each once. How do you know which garden has fewer?", "CompareCampFlower"),
        ("Find a partner", "Can every sheep find a friend?", "Put 4 sheep in each group. Spread one group out.", "Pair them. Spreading out does not add sheep. Both groups still have four.", "CompareCampSheep"),
        ("Build a balance", "Make the leaf piles equal.", "Start with 2 leaves on the left and 5 on the right. Change only the left pile.", "Add three to match. Now start with 6 and 4. Can you remove instead?", "CompareCampLeaf"),
        ("Spot the extras", "How many extra apples are there?", "Use 7 on the left and 4 on the right. Match partners first.", "Count only the unpaired apples. There are three extra on the left.", "CompareCampApple"),
        ("Empty is a number", "What happens when a group is empty?", "Make an empty garden and a garden with 3 flowers. Then empty both.", "Zero flowers is still a count. Two empty groups are equal.", "CompareCampFlower"),
        ("Meet the signs", "Which sign belongs between 3 and 5?", "Build both groups. Write 3 < 5, 5 > 3 and 4 = 4 after comparing.", "The open side faces the greater number. Say less than, greater than or equal to.", "CompareCampSheep"),
        ("A new camp", "Can you solve it with different things?", "Try 4 spoons and 6 spoons. Make the groups equal, then ask how many extra.", "Rearrange and swap sides. Explain your idea without relying on the picture you saw before.", "CompareCampLeaf"),
    ]
    for p in range(2):
        page(c, "Choose a little mission", "Read aloud, build with tokens or real objects, and follow your child's ideas.", p + 2)
        for i, m in enumerate(missions[p * 4:(p + 1) * 4]):
            x = 38 + (i % 2) * 266
            y = 390 if i < 2 else 65
            mission(c, *m[:4], x, y, 253, 310, m[4])
        c.showPage()

    page(c, "Two places to compare", "Put objects in each camp. Touch each once to count. Line up partners to compare.", 4)
    for x, label in [(38, "LEFT CAMP"), (312, "RIGHT CAMP")]:
        text(c, label, x + 16, 650, 15, TEAL, True)
        c.setStrokeColor(TEAL)
        c.setLineWidth(2)
        c.roundRect(x, 265, 245, 355, 18, fill=0, stroke=1)
    text(c, "What do you notice?", 38, 208, 18, NAVY, True)
    paragraph(c, "More / Fewer / Equal / How many extra?\nCan you make both camps equal? What changes when you move just one?", 38, 180, W - 76, 13, 22)
    text(c, "LEFT COUNT: ______          SIGN: ______          RIGHT COUNT: ______", 38, 92, 11, TEAL, True)
    c.showPage()

    page(c, "Little things to count", "Cut the cards with a grown-up. Ten of each object. Print twice for larger same-object groups.", 5)
    icons = ["CompareCampApple", "CompareCampFlower", "CompareCampLeaf", "CompareCampSheep"]
    for row in range(8):
        for col in range(5):
            x, y = 40 + col * 104, 620 - row * 76
            c.setStrokeColor(HexColor("#C9DBD5"))
            c.roundRect(x, y, 94, 67, 7, fill=0, stroke=1)
            art(c, icons[row // 2], x + 19, y + 6, 56, 56)
    c.showPage()

    page(c, "Your explorer passport", "Draw, stamp or add a sticker when you finish a camp adventure. Choose your own route.", 6)
    for r, region in enumerate(["WOODLAND", "OCEAN", "SKY", "SPACE", "TRAVEL", "BUILDERS"]):
        yy = 655 - r * 89
        text(c, region, 40, yy + 19, 11, TEAL, True)
        for col in range(4):
            xx = 170 + col * 94
            c.setStrokeColor(HexColor("#C9DBD5"))
            c.roundRect(xx, yy - 20, 74, 66, 10, fill=0, stroke=1)
            text(c, "CAMP " + str(col + 1), xx + 12, yy - 9, 8, TEAL)
    art(c, "CompareCampBadge", 39, 70, 75, 75)
    text(c, "My favourite discovery: ______________________________", 132, 121, 11)
    text(c, "Next time I want to explore: __________________________", 132, 98, 11)
    c.showPage()
    c.save()
    print(OUT)


if __name__ == "__main__":
    main()
