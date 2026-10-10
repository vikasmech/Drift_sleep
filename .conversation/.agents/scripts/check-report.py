import fitz
from pathlib import Path

out = Path(".agents/outputs")
out.mkdir(parents=True, exist_ok=True)
doc = fitz.open("deliverables/sleep-app-competitive-analysis.pdf")
for i, page in enumerate(doc):
    if len(page.get_text().strip()) < 200:
        raise RuntimeError(f"Blank page {i+1}")
    for block in page.get_text("dict")["blocks"]:
        if block["type"] == 0:
            x0, y0, x1, y1 = block["bbox"]
            if x0 < 0 or y0 < 0 or x1 > 612 or y1 > 792:
                raise RuntimeError(f"Out of bounds text on page {i+1}: {block['bbox']}")
for i in [0, 1, 2, 4, 8]:
    doc[i].get_pixmap(matrix=fitz.Matrix(1.5, 1.5)).save(str(out / f"page-{i+1}.png"))
print(f"Checked {len(doc)} pages: no blank pages or out-of-bounds text; rendered 5 samples.")
