using System.Drawing;
using System.Reflection;
using System.Windows.Forms;

namespace Netch.Utils;

public static class ThemeManager
{
    public static readonly Color Background = Color.FromArgb(18, 18, 23);
    public static readonly Color Surface = Color.FromArgb(28, 28, 36);
    public static readonly Color Input = Color.FromArgb(36, 36, 46);
    public static readonly Color Accent = Color.FromArgb(0, 145, 234);
    public static readonly Color AccentHighlight = Color.FromArgb(10, 165, 255);
    public static readonly Color PrimaryText = Color.WhiteSmoke;
    public static readonly Color SecondaryText = Color.FromArgb(210, 210, 218);

    public static void ApplyDark(Form form)
    {
        EnableDoubleBuffer(form);

        form.BackColor = Background;
        form.ForeColor = PrimaryText;

        if (form.MainMenuStrip is not null)
            ConfigureToolStrip(form.MainMenuStrip);

        Apply(form.Controls);
    }

    private static void Apply(Control.ControlCollection controls)
    {
        foreach (Control control in controls)
        {
            switch (control)
            {
                case ToolStrip strip:
                    ConfigureToolStrip(strip);
                    break;

                case StatusStrip statusStrip:
                    ConfigureToolStrip(statusStrip);
                    break;

                case Button button:
                    ApplyButton(button);
                    break;

                case TextBoxBase textBox:
                    textBox.BackColor = Input;
                    textBox.ForeColor = PrimaryText;
                    break;

                case ComboBox comboBox:
                    comboBox.BackColor = Input;
                    comboBox.ForeColor = PrimaryText;
                    comboBox.FlatStyle = FlatStyle.Flat;
                    break;

                case CheckedListBox checkedListBox:
                    checkedListBox.BackColor = Input;
                    checkedListBox.ForeColor = PrimaryText;
                    break;

                case ListBox listBox:
                    listBox.BackColor = Input;
                    listBox.ForeColor = PrimaryText;
                    break;

                case RichTextBox richTextBox:
                    richTextBox.BackColor = Input;
                    richTextBox.ForeColor = PrimaryText;
                    break;

                case LinkLabel linkLabel:
                    linkLabel.LinkColor = Accent;
                    linkLabel.ActiveLinkColor = AccentHighlight;
                    linkLabel.VisitedLinkColor = Accent;
                    linkLabel.ForeColor = PrimaryText;
                    break;

                case Label label:
                    label.ForeColor = SecondaryText;
                    break;

                case GroupBox:
                case Panel:
                case FlowLayoutPanel:
                case TableLayoutPanel:
                case TabControl:
                case TabPage:
                    control.BackColor = Surface;
                    control.ForeColor = PrimaryText;
                    EnableDoubleBuffer(control);
                    break;
            }

            if (control.HasChildren)
                Apply(control.Controls);
        }
    }

    private static void ApplyButton(Button button)
    {
        button.FlatStyle = FlatStyle.Flat;
        button.FlatAppearance.BorderSize = 0;
        button.BackColor = Accent;
        button.ForeColor = Color.White;
        button.FlatAppearance.MouseOverBackColor = AccentHighlight;
        button.FlatAppearance.MouseDownBackColor = AccentHighlight;
    }

    private static void ConfigureToolStrip(ToolStrip strip)
    {
        strip.BackColor = Surface;
        strip.ForeColor = PrimaryText;
        strip.Renderer = new ToolStripProfessionalRenderer(new DarkColorTable());
    }

    private static void EnableDoubleBuffer(Control control)
    {
        typeof(Control)
            .GetProperty("DoubleBuffered", BindingFlags.Instance | BindingFlags.NonPublic)?
            .SetValue(control, true, null);
    }

    private class DarkColorTable : ProfessionalColorTable
    {
        public override Color MenuItemSelected => Accent;
        public override Color MenuItemBorder => AccentHighlight;
        public override Color ToolStripDropDownBackground => Surface;
        public override Color MenuBorder => Surface;
        public override Color MenuItemSelectedGradientBegin => Accent;
        public override Color MenuItemSelectedGradientEnd => Accent;
        public override Color MenuItemPressedGradientBegin => Accent;
        public override Color MenuItemPressedGradientEnd => AccentHighlight;
        public override Color StatusStripGradientBegin => Surface;
        public override Color StatusStripGradientEnd => Surface;
    }
}
