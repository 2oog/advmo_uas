from escpos.printer import Serial
from flask import Flask, request, jsonify
import textwrap
import pendulum
import atexit

# -------------------
# Printer configuration
# -------------------
LINE_WIDTH = 32

thermal = Serial(
    devfile="COM3",
    baudrate=9600,
    bytesize=8,
    parity="N",
    stopbits=1,
    timeout=1,
    dsrdtr=True,
)

# default printer settings
thermal.set_with_default(
    align="left",
    font="a",
    bold=False,
    underline=0,
    density=9,
)

# Ensure printer is closed cleanly on exit
@atexit.register
def close_printer():
    try:
        thermal.close()
    except Exception:
        pass


# -------------------
# Helper functions
# -------------------
def set_normal(align: str = "left"):
    thermal.set(align=align, normal_textsize=True, bold=False, underline=0)


def set_big(align: str = "center"):
    thermal.set(align=align, double_width=True, double_height=True, bold=False, underline=0)


def left_right(line_left: str, line_right: str, width: int = LINE_WIDTH) -> str:
    line_left = (line_left or "")[:width]
    line_right = (line_right or "")[:width]
    space = width - len(line_left) - len(line_right)
    if space < 1:
        space = 1
    return f"{line_left}{' ' * space}{line_right}"


def text_wrap(s: str, width: int = LINE_WIDTH):
    for part in textwrap.wrap(s or "", width=width, break_long_words=True, break_on_hyphens=False):
        thermal.textln(part)


def hr(char: str = "-"):
    set_normal("left")
    thermal.textln(char * LINE_WIDTH)


def fmt_int(n, sep=".") -> str:
    s = f"{int(n):,}"
    return s.replace(",", sep)


# -------------------
# Core print function (expects same JSON shape as fetch_order)
# -------------------
def print_receipt(order: dict):
    """
    Expects JSON like:
    {
      "id": 2,
      "order_date": "2025-12-13T13:37:01.000000Z",
      "subtotal": 49000,
      "tax_amount": 4900,
      "total_amount": 53900,
      "payment_method": "QRIS",
      "payment_status": "PAID",
      "order_items": [
        {
          "menu_name": "Sate Ayam (10x)",
          "quantity": 1,
          "price_at_time": 35000,
          "subtotal": 35000
        },
        ...
      ]
    }
    """
    # Header
    set_big("center")
    thermal.textln("Resto POS")

    set_normal("center")
    thermal.textln("Jl. Raya Kedung Baruk No.98,\nSurabaya. Telp: (031) 8721731")
    hr()

    # Order info
    set_normal("left")
    thermal.textln("No    : " + str(order.get("id", "")))
    thermal.textln("Kasir : Admin")
    order_date_str = order.get("order_date")
    if order_date_str:
        dt_wib = pendulum.parse(order_date_str).in_timezone("Asia/Jakarta")
        thermal.textln("Tgl   : " + dt_wib.strftime("%d-%m-%Y %H:%M:%S"))
    else:
        thermal.textln("Tgl   : -")

    hr()

    # Items
    for item in order.get("order_items", []):
        text_wrap(item.get("menu_name", ""), LINE_WIDTH)
        left = f'{fmt_int(item.get("price_at_time", 0), sep=".")} x {fmt_int(item.get("quantity", 0), sep=".")}'
        right = fmt_int(item.get("subtotal", 0), sep=".")
        thermal.textln(left_right(left, right))

    hr()

    # Totals / payment
    total_amount = fmt_int(order.get("total_amount", 0), sep=".")
    thermal.textln(left_right("Total", total_amount))

    payment_method = str(order.get("payment_method", "QRIS"))
    thermal.textln(left_right(payment_method, total_amount))

    hr()

    # Footer
    set_normal("center")
    thermal.textln("Terima kasih")
    thermal.textln("Silahkan datang kembali")
    thermal.ln(3)


# -------------------
# Flask app
# -------------------
app = Flask(__name__)


@app.post("/print/order")
def print_order():
    """
    Accepts JSON identical to fetch_order() response.
    Example POST to:
      http://localhost:8800/print/order
    """
    data = request.get_json(silent=True)

    if not isinstance(data, dict):
        return jsonify({"error": "Invalid JSON payload"}), 400

    try:
        print_receipt(data)
        return jsonify({"status": "ok"}), 200
    except Exception as exc:
        app.logger.exception("Printing failed")
        return jsonify({"error": str(exc)}), 500


if __name__ == "__main__":
    # Listen on port 8800 as requested
    app.run(host="0.0.0.0", port=8800)
