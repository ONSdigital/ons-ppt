import colorsys
import logging

import streamlit as st

logger = logging.getLogger(__name__)

logging.basicConfig(level=logging.INFO)


def validate_colours(colours: list) -> bool:
    """
    Validates a list of colour strings.

    Args:
        colours (list): A list of colour strings in hex format.

    Raises:
        ValueError: If any colour is None, not a string, or not in valid hex
        format.
    """
    for colour in colours:
        if colour is None:
            msg = "Colour cannot be None"
            logger.error(msg)
            raise ValueError(msg)
        if (
            not isinstance(colour, str)
            or not colour.startswith("#")
            or len(colour) not in [4, 7]  # noqa
        ):
            msg = f"Invalid colour format: {colour}"
            logger.error(msg)
            raise ValueError(msg)
        if not all(c in "0123456789ABCDEFabcdef" for c in colour.lstrip("#")):
            msg = f"Invalid hex characters in colour: {colour}"
            logger.error(msg)
            raise ValueError(msg)


def hex_to_rgb(hex_code):
    """
    Converts a hex color code to an RGB dictionary.

    Args:
        hex_code (str): A string representing a hex color code,
        e.g., '#AABBCC'.
    Returns:
        dict: A dictionary with keys 'r', 'g', and 'b' representing the RGB
        values.
    """
    hex_code = hex_code.lstrip("#")
    if len(hex_code) == 3:
        # Expand short hex to full length
        hex_code = "".join([c * 2 for c in hex_code])
    # Convert hex string to integer
    num = int(hex_code, 16)
    return {
        "r": (num >> 16) & 255,  # Extract red channel (top 8 bits)
        "g": (num >> 8) & 255,  # Extract green channel (middle 8 bits)
        "b": num & 255,  # Extract blue channel (bottom 8 bits)
    }


def normalise_rgb(rgb):
    """
    Normalises RGB values to a range of 0-1.

    Args:
        rgb (dict): A dictionary with keys 'r', 'g', and 'b'.
    Returns:
        dict: A dictionary with normalised RGB values.
    """
    return {k: v / 255.0 for k, v in rgb.items()}


def apply_gamma_correction(rgb):
    """
    Applies gamma correction to RGB values.

    Args:
        rgb (dict): A dictionary with keys 'r', 'g', and 'b'.
    Returns:
        dict: A dictionary with gamma-corrected RGB values.
    """

    def correct(channel):
        if channel <= 0.03928:
            return channel / 12.92
        else:
            return ((channel + 0.055) / 1.055) ** 2.4

    return {k: correct(v) for k, v in rgb.items()}


def calculate_relative_luminance(rgb):
    """
    Calculates the relative luminance of an RGB color.

    Args:
        rgb (dict): A dictionary with keys 'r', 'g', and 'b'.
    Returns:
        float: The relative luminance value.
    """
    r, g, b = rgb["r"], rgb["g"], rgb["b"]
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def calculate_contrast_ratio(luminances):
    """
    Calculates the contrast ratio between two colours.

    Args:
        luminances (list): A list of two luminance values.
    Returns:
        float: The contrast ratio between the two luminances.
    """
    L1 = max(luminances)
    L2 = min(luminances)
    if L1 == 0 and L2 == 0:
        return 1.0
    return (L1 + 0.05) / (L2 + 0.05)


def contrast_ratio_check(contrast_ratio):
    """
    Checks the contrast ratio between two colours and returns the result.

    Args:
        contrast_ratio (float): The contrast ratio to check.
    Returns:
        dict: A dictionary containing the results of the checks for different
        text types.
    """
    checks = {
        "normal_text_AA": False,
        "normal_text_AAA": False,
        "large_text_AA": False,
        "large_text_AAA": False,
        "graphical_AA": False,
    }
    if contrast_ratio >= 3:
        for key in ["large_text_AA", "graphical_AA"]:
            checks[key] = True
    if contrast_ratio >= 4.5:
        for key in ["normal_text_AA", "large_text_AAA"]:
            checks[key] = True
    if contrast_ratio >= 7:
        for key in ["normal_text_AAA"]:
            checks[key] = True
    return checks


def format_ratio(ratio):
    """
    Formats the contrast ratio to a string with up to 2 decimal places,
    dropping trailing zeros.

    Args:
        ratio (float): The contrast ratio to format.
    Returns:
        str: The formatted contrast ratio string.
    """
    # Format with up to 2 decimal places, but drop trailing zeros
    return f"{ratio:.2f}".rstrip("0").rstrip(".")


def blend_colours(fg_rgb, bg_rgb, alpha):
    """
    Blends foreground and background RGB colours using alpha.
    Returns the composited RGB colour.

    Args:
        fg_rgb (dict): Foreground RGB values.
        bg_rgb (dict): Background RGB values.
        alpha (float): Alpha value for blending (0.0 to 1.0).
    Returns:
        dict: A dictionary with blended RGB values.
    """
    return {key: alpha * fg_rgb[key] + (1 - alpha) * bg_rgb[key] for key in ["r", "g", "b"]}  # noqa


def adjust_lightness(hex_colour, lightness):
    """
    Adjust the lightness of a hex colour (0.0 to 1.0).

    Args:
        hex_colour (str): A string representing a hex colour code,
        e.g., '#AABBCC'.
        lightness (float): Lightness value between 0.0 (black) and 1.0 (white).

    Returns:
        str: A hex colour code with adjusted lightness.
    """
    rgb = hex_to_rgb(hex_colour)
    # Convert to 0-1 range for colorsys
    r, g, b = rgb["r"] / 255.0, rgb["g"] / 255.0, rgb["b"] / 255.0
    h, _, s = colorsys.rgb_to_hls(r, g, b)
    # Replace lightness with user value
    r2, g2, b2 = colorsys.hls_to_rgb(h, lightness, s)
    # Convert back to 0-255 and hex
    return "#{:02x}{:02x}{:02x}".format(
        int(r2 * 255),
        int(g2 * 255),
        int(b2 * 255),
    )


def get_lightness(hex_colour):
    """
    Return the lightness (0-1) of a hex colour using HLS.

    Args:
        hex_colour (str): A string representing a hex colour code,
        e.g., '#AABBCC'.
    Returns:
        float: Lightness value between 0.0 (black) and 1.0 (white).
    """
    rgb = hex_to_rgb(hex_colour)
    r, g, b = rgb["r"] / 255.0, rgb["g"] / 255.0, rgb["b"] / 255.0
    _, l, _ = colorsys.rgb_to_hls(r, g, b)
    return l


def show_instructions():
    st.title("Colour Contrast Checker (WCAG)")
    st.markdown("## How to Use This Tool")
    st.markdown(
        """
    **Colour Contrast Checker (WCAG)** helps you evaluate the accessibility of
    colour combinations for text, graphics, and UI components according to
    [WCAG](https://www.w3.org/WAI/standards-guidelines/wcag/) standards.

    **Instructions:**
    - Use the two colour pickers at the top to select foreground and
    background colours.
    - The tool calculates the contrast ratio and checks if your combination
    meets WCAG requirements for:
      - **Normal Text** (AA/AAA)
      - **Large Text** (AA/AAA)
      - **Graphical/UI Components** (AA/AAA)
    - Each WCAG item shows a brief description and a coloured "Pass" or "Fail"
    indicator.
    - The colour swatches at the bottom show your selected colours side by
    side.

    **Tips:**
    - Aim for a contrast ratio of at least **4.5:1** for normal text and
    **3:1** for large text or graphical elements.
    - Use this tool to ensure your designs are accessible to all users,
    including those with visual impairments.
    """
    )
    st.markdown("---")


def colour_selection_ui():
    st.markdown("## Select Colours")
    st.caption("Tip: Click the colour swatch to open the slider controls.")

    col1, col2 = st.columns(2)
    with col1:
        colour1 = st.color_picker("Pick foreground colour", "#008000")
        default_lightness1 = get_lightness(colour1)
        lightness1 = st.slider(
            "Lightness (foreground)",
            min_value=0.0,
            max_value=1.0,
            value=default_lightness1,
            step=0.01,
            key="lightness1",
        )
        colour1 = adjust_lightness(colour1, lightness1)
        alpha = st.slider(
            "Foreground alpha (opacity)",
            min_value=0.0,
            max_value=1.0,
            value=1.0,
            step=0.01,
        )
    with col2:
        colour2 = st.color_picker("Pick background colour", "#FFFFFF")
        default_lightness2 = get_lightness(colour2)
        lightness2 = st.slider(
            "Lightness (background)",
            min_value=0.0,
            max_value=1.0,
            value=default_lightness2,
            step=0.01,
            key="lightness2",
        )
        colour2 = adjust_lightness(colour2, lightness2)
    return colour1, colour2, alpha


def show_colour_swatches(colour1, colour2, alpha, rgb1):
    fg_rgba = f"rgba({rgb1['r']},{rgb1['g']},{rgb1['b']},{alpha})"
    swatch1, swatch2 = st.columns(2)
    with swatch1:
        st.markdown(
            f"""
            <div style="width: 100px; height: 50px; background: {colour2};
            border: 1px solid #888;">
                <div style="width: 100%; height: 100%; background: {fg_rgba};"
                ></div>
            </div>
            """,
            unsafe_allow_html=True,
        )
        st.markdown(f"{colour1.upper()} (Alpha: {alpha})")
    with swatch2:
        st.markdown(
            f"""
            <div style="width: 100px; height: 50px; background: {colour2};
            border: 1px solid #888;"></div>
            """,
            unsafe_allow_html=True,
        )
        st.markdown(f"{colour2.upper()}")


def show_wcag_results(ratio, checks, colour2, fg_rgba):
    st.markdown(
        f"""
        <div style="
            display: flex;
            justify-content: center;
            align-items: center;
            margin: 24px 0;
        ">
            <div style="
                border: 2px solid #888;
                border-radius: 12px;
                padding: 18px 36px;
                background: #f9f9f9;
                font-size: 2em;
                font-weight: bold;
                color: #222;
                box-shadow: 0 2px 8px rgba(0,0,0,0.07);
                text-align: center;
            ">
                Contrast Ratio: <span style="color:#00000;">
                {format_ratio(ratio)}:1</span>
            </div>
        </div>
        """,
        unsafe_allow_html=True,
    )

    wcag_items = {
        "normal_text_AA": (
            "Normal Text AA",
            "Contrast ratio ≥ 4.5:1 for normal text (WCAG AA)",
        ),
        "normal_text_AAA": (
            "Normal Text AAA",
            "Contrast ratio ≥ 7:1 for normal text (WCAG AAA)",
        ),
        "large_text_AA": (
            "Large Text AA",
            "Contrast ratio ≥ 3:1 for large text (WCAG AA)",
        ),
        "large_text_AAA": (
            "Large Text AAA",
            "Contrast ratio ≥ 4.5:1 for large text (WCAG AAA)",
        ),
        "graphical_AA": (
            "Graphical AA",
            "Contrast ratio ≥ 3:1 for graphics and UI components (WCAG AA)",
        ),
    }

    st.markdown("### WCAG Checks:")

    example_text = "Sample Text"

    # Normal Text
    st.markdown("#### Normal Text")
    for key in ["normal_text_AA", "normal_text_AAA"]:
        title, desc = wcag_items[key]
        result = checks[key]
        colour = "green" if result else "red"
        status = "Pass" if result else "Fail"
        st.markdown(
            f"<b>{title}</b>: {desc} "
            f"<span style='color:{colour};font-weight:bold;'>{status}</span>",
            unsafe_allow_html=True,
        )
    st.markdown(
        f"""
        <span style='padding:2px 8px; background:{colour2}; color:{fg_rgba};
        border-radius:4px; border:1px solid #ccc;'>{example_text}</span>
        """,
        unsafe_allow_html=True,
    )

    # Large Text
    st.markdown("#### Large Text")
    for key in ["large_text_AA", "large_text_AAA"]:
        title, desc = wcag_items[key]
        result = checks[key]
        colour = "green" if result else "red"
        status = "Pass" if result else "Fail"
        st.markdown(
            f"<b>{title}</b>: {desc} "
            f"<span style='color:{colour};font-weight:bold;'>{status}</span>",
            unsafe_allow_html=True,
        )
    st.markdown(
        f"""
        <span style='font-size:1.5em; padding:2px 8px; background:{colour2};
        color:{fg_rgba}; border-radius:4px; border:1px solid #ccc;'>
        {example_text}</span>
        """,
        unsafe_allow_html=True,
    )

    # Graphical/UI
    st.markdown("#### Graphical / UI Components")
    title, desc = wcag_items["graphical_AA"]
    result = checks["graphical_AA"]
    colour = "green" if result else "red"
    status = "Pass" if result else "Fail"
    st.markdown(
        f"<b>{title}</b>: {desc} "
        f"<span style='color:{colour};font-weight:bold;'>{status}</span>",
        unsafe_allow_html=True,
    )
    st.markdown(
        f"""
        <span style='
            display: inline-block;
            padding: 8px 24px;
            background: {colour2};
            color: {fg_rgba};
            border-radius: 24px;
            border: 1.5px solid #ccc;
            font-weight: 600;
            box-shadow: 0 2px 6px rgba(0,0,0,0.08);
            font-family: inherit;
            letter-spacing: 0.5px;
        '>{example_text}</span>
        """,
        unsafe_allow_html=True,
    )


def main():
    show_instructions()
    try:
        colour1, colour2, alpha = colour_selection_ui()
        validate_colours([colour1, colour2])
    except ValueError as e:
        st.error(f"Colour input error: {e}")
        return

    rgb1 = hex_to_rgb(colour1)
    rgb2 = hex_to_rgb(colour2)
    blended_rgb1 = blend_colours(rgb1, rgb2, alpha)
    norm1 = normalise_rgb(blended_rgb1)
    norm2 = normalise_rgb(rgb2)
    gamma1 = apply_gamma_correction(norm1)
    gamma2 = apply_gamma_correction(norm2)
    lum1 = calculate_relative_luminance(gamma1)
    lum2 = calculate_relative_luminance(gamma2)
    ratio = calculate_contrast_ratio([lum1, lum2])
    checks = contrast_ratio_check(ratio)
    fg_rgba = f"rgba({rgb1['r']},{rgb1['g']},{rgb1['b']},{alpha})"

    show_colour_swatches(colour1, colour2, alpha, rgb1)
    show_wcag_results(ratio, checks, colour2, fg_rgba)


if __name__ == "__main__":
    main()
