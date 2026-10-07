// Small helper layer over docx-js so content files stay readable.
const fs = require("fs");
const {
  Paragraph, TextRun, HeadingLevel, Table, TableRow, TableCell, WidthType, ShadingType,
  BorderStyle, ImageRun, AlignmentType, PageBreak, LevelFormat,
} = require("docx");

const C = {
  ink: "2B2420", muted: "6B5E52", accent: "8A1C1C", head: "3A2E28",
  rowAlt: "F4EEE2", headFill: "3A2E28", codeFill: "F2EFEA", noteFill: "F6EBDD", border: "BFB3A3",
};
const FONT = { body: "Calibri", head: "Georgia", mono: "Consolas" };

let CONTENT_WIDTH = 9638; // A4 portrait, 2 cm margins
const setWidth = (w) => { CONTENT_WIDTH = w; };

// Inline markup: **bold**, *italic*, `code`
function runs(text, base = {}) {
  const out = [];
  const re = /(\*\*[^*]+\*\*|`[^`]+`|\*[^*]+\*)/g;
  let last = 0, m;
  while ((m = re.exec(text)) !== null) {
    if (m.index > last) out.push(new TextRun({ text: text.slice(last, m.index), ...base }));
    const t = m[0];
    if (t.startsWith("**")) out.push(new TextRun({ text: t.slice(2, -2), bold: true, ...base }));
    else if (t.startsWith("`")) out.push(new TextRun({ text: t.slice(1, -1), font: FONT.mono, size: 18, color: C.accent, ...base }));
    else out.push(new TextRun({ text: t.slice(1, -1), italics: true, ...base }));
    last = m.index + t.length;
  }
  if (last < text.length) out.push(new TextRun({ text: text.slice(last), ...base }));
  return out;
}

const H1 = (t) => new Paragraph({ heading: HeadingLevel.HEADING_1, pageBreakBefore: true, children: [new TextRun(t)] });
const H1nb = (t) => new Paragraph({ heading: HeadingLevel.HEADING_1, children: [new TextRun(t)] });
const H2 = (t) => new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun(t)] });
const H3 = (t) => new Paragraph({ heading: HeadingLevel.HEADING_3, children: [new TextRun(t)] });
const P = (t, opts = {}) => new Paragraph({ children: runs(t), spacing: { after: 120 }, ...opts });
const Bul = (items, level = 0) => items.flatMap((it) =>
  Array.isArray(it) ? Bul(it, level + 1)
    : [new Paragraph({ numbering: { reference: "bullets", level }, children: runs(it), spacing: { after: 60 } })]);
let numInstance = 0;
const Num = (items) => {
  numInstance += 1;
  const inst = numInstance;
  return items.map((it) => new Paragraph({ numbering: { reference: "numbers", level: 0, instance: inst }, children: runs(it), spacing: { after: 60 } }));
};
const Note = (t, label = "Note") => new Paragraph({
  children: [new TextRun({ text: label + ": ", bold: true, color: C.accent }), ...runs(t)],
  shading: { type: ShadingType.CLEAR, color: "auto", fill: C.noteFill },
  border: { left: { style: BorderStyle.SINGLE, size: 18, color: C.accent, space: 6 } },
  spacing: { before: 80, after: 160 }, indent: { left: 120, right: 120 },
});
const Code = (src, size = 17) => src.replace(/\t/g, "    ").split("\n").map((line, i, arr) => new Paragraph({
  children: [new TextRun({ text: line.length ? line : " ", font: FONT.mono, size })],
  shading: { type: ShadingType.CLEAR, color: "auto", fill: C.codeFill },
  spacing: { before: i === 0 ? 80 : 0, after: i === arr.length - 1 ? 160 : 0, line: 240 },
  indent: { left: 120, right: 120 },
}));
const Mono = (lines, size = 12) => lines.map((line) => new Paragraph({
  children: [new TextRun({ text: line.length ? line : " ", font: FONT.mono, size })],
  spacing: { before: 0, after: 0, line: 200 },
}));
const Break = () => new Paragraph({ children: [new PageBreak()] });
const Spacer = () => new Paragraph({ children: [new TextRun("")] });

const cellBorder = { style: BorderStyle.SINGLE, size: 4, color: C.border };
const borders = { top: cellBorder, bottom: cellBorder, left: cellBorder, right: cellBorder };

// widths: relative numbers -> scaled to content width
function Tbl(headers, rows, rel) {
  const n = headers.length;
  rel = rel || Array(n).fill(1);
  const sum = rel.reduce((a, b) => a + b, 0);
  const widths = rel.map((r) => Math.floor((r / sum) * CONTENT_WIDTH));
  widths[n - 1] += CONTENT_WIDTH - widths.reduce((a, b) => a + b, 0);
  const cell = (text, i, isHead, alt) => new TableCell({
    borders, width: { size: widths[i], type: WidthType.DXA },
    shading: { type: ShadingType.CLEAR, color: "auto", fill: isHead ? C.headFill : alt ? C.rowAlt : "FFFFFF" },
    margins: { top: 60, bottom: 60, left: 100, right: 100 },
    children: String(text).split("\n").map((line) => new Paragraph({
      children: isHead ? [new TextRun({ text: line, bold: true, color: "FFFFFF", size: 19 })] : runs(line, { size: 19 }),
      spacing: { after: 20 },
    })),
  });
  return new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA }, columnWidths: widths,
    rows: [
      new TableRow({ tableHeader: true, children: headers.map((h, i) => cell(h, i, true, false)) }),
      ...rows.map((r, ri) => new TableRow({ children: r.map((c, i) => cell(c, i, false, ri % 2 === 1)) })),
    ],
  });
}
// Two-column key/value card
const KV = (pairs) => Tbl(["Field", "Value"], pairs, [1, 3.4]);

function Img(path, widthPx, caption) {
  const buf = fs.readFileSync(path);
  // read PNG size from header
  const w = buf.readUInt32BE(16), h = buf.readUInt32BE(20);
  const height = Math.round((widthPx * h) / w);
  const out = [new Paragraph({ alignment: AlignmentType.CENTER, children: [new ImageRun({ type: "png", data: buf, transformation: { width: widthPx, height }, altText: { title: caption || "image", description: caption || "image", name: "img" } })] })];
  if (caption) out.push(new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: caption, italics: true, size: 18, color: C.muted })], spacing: { after: 200 } }));
  return out;
}

const numbering = {
  config: [
    { reference: "bullets", levels: [
      { level: 0, format: LevelFormat.BULLET, text: "•", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 500, hanging: 260 } } } },
      { level: 1, format: LevelFormat.BULLET, text: "–", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 1000, hanging: 260 } } } },
      { level: 2, format: LevelFormat.BULLET, text: "·", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 1500, hanging: 260 } } } },
    ] },
    { reference: "numbers", levels: [
      { level: 0, format: LevelFormat.DECIMAL, text: "%1.", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 500, hanging: 300 } } } },
    ] },
  ],
};

const styles = {
  default: { document: { run: { font: FONT.body, size: 21, color: C.ink } } },
  paragraphStyles: [
    { id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
      run: { size: 36, bold: true, font: FONT.head, color: C.accent },
      paragraph: { spacing: { before: 120, after: 200 }, outlineLevel: 0,
        border: { bottom: { style: BorderStyle.SINGLE, size: 8, color: C.accent, space: 4 } } } },
    { id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
      run: { size: 28, bold: true, font: FONT.head, color: C.head },
      paragraph: { spacing: { before: 280, after: 120 }, outlineLevel: 1 } },
    { id: "Heading3", name: "Heading 3", basedOn: "Normal", next: "Normal", quickFormat: true,
      run: { size: 23, bold: true, font: FONT.head, color: C.muted },
      paragraph: { spacing: { before: 200, after: 80 }, outlineLevel: 2 } },
  ],
};

module.exports = { H1, H1nb, H2, H3, P, Bul, Num, Note, Code, Mono, Break, Spacer, Tbl, KV, Img, runs, numbering, styles, C, FONT, setWidth };
