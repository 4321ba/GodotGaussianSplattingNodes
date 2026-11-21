import json
import re
import sys
from pathlib import Path

# Characters that have special meaning in Typst markup mode and must be escaped
TYPST_ESCAPE_CHARS = set(r'\#$*_`<>@[]~/=-+."\'')

# Separator placed between array elements in the generated .typ file
PROMPT_SEPARATOR = "\n  ],\n  [\n"


def sanitize_text(text: str) -> str:
    """Normalize newlines/spaces and strip invalid ASCII control characters."""
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    text = text.replace("\u00a0", " ")
    return "".join(ch for ch in text if ch in ("\n", "\t") or (ord(ch) >= 32 and ord(ch) != 127))


def escape_typst_inline(text: str) -> str:
    """Escape Typst special characters so arbitrary prose, URLs, XML, and code compile safely."""
    return "".join("\\" + ch if ch in TYPST_ESCAPE_CHARS else ch for ch in text)


def format_multiline_typst(text: str) -> str:
    """
    Convert plain text (including pasted code/logs) into valid Typst markup:
    - Preserves paragraph breaks (\n\n)
    - Preserves single line breaks (\n) using Typst hard line breaks ( backslash )
    - Preserves leading indentation using Typst non-breaking spaces (~)
    """
    text = sanitize_text(text).strip("\n")
    if not text:
        return ""

    paragraphs = re.split(r"\n{2,}", text)
    formatted_paragraphs = []

    for para in paragraphs:
        lines = para.split("\n")
        formatted_lines = []
        for line in lines:
            expanded = line.replace("\t", "    ")
            stripped = expanded.lstrip(" ")
            indent_len = len(expanded) - len(stripped)
            indent_prefix = "~" * indent_len

            escaped_body = escape_typst_inline(stripped)
            formatted_lines.append(f"{indent_prefix}{escaped_body}")

        formatted_paragraphs.append(" \\\n".join(formatted_lines))

    return "\n\n".join(formatted_paragraphs)


def format_prompt_entry(attachments: list[str], text: str) -> str:
    """Format a single user turn with optional italic attachment headers."""
    parts = []

    if attachments:
        att_lines = [
            f"_{escape_typst_inline(sanitize_text(name))} akkori változata_"
            for name in attachments
        ]
        parts.append(" \\\n".join(att_lines))

    formatted_text = format_multiline_typst(text)
    if formatted_text:
        parts.append(formatted_text)

    return " \\\n".join(parts)


def convert_json_to_typst(input_path: Path, output_path: Path) -> int:
    with input_path.open("r", encoding="utf-8") as f:
        messages = json.load(f)

    entries = []
    for msg in messages:
        if msg.get("role") != "user":
            continue

        attachments = []
        text_chunks = []

        for item in msg.get("contents", []):
            item_type = item.get("type")
            if item_type == "attachment":
                name = item.get("attachment", {}).get("name")
                if name:
                    attachments.append(name)
            elif item_type == "text":
                content = item.get("content", "")
                if content:
                    text_chunks.append(content)

        full_text = "\n\n".join(text_chunks)
        entry = format_prompt_entry(attachments, full_text)
        if entry:
            entries.append(entry)

    if entries:
        array_body = "(\n  [\n" + PROMPT_SEPARATOR.join(entries) + "\n  ],\n)"
    else:
        array_body = "()"

    output_content = (
        f"// Auto-generated from {input_path.name}\n"
        f"#let prompts = {array_body}\n"
    )

    output_path.write_text(output_content, encoding="utf-8")
    return len(entries)


if __name__ == "__main__":
    in_file = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("Gemini-_52.json")
    out_file = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("prompts.typ")

    count = convert_json_to_typst(in_file, out_file)
    print(f"Exported {count} user prompts to {out_file}")
