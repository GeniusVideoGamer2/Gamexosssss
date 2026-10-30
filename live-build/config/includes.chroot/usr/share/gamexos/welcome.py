#!/usr/bin/env python3

import subprocess
from pathlib import Path

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gdk, Gtk


CSS_PATH = Path("/usr/share/gamexos/welcome.css")


class WelcomeWindow:
    def __init__(self):
        self.window = Gtk.Window(title="GameXOSTR")
        self.window.set_default_size(1080, 720)
        self.window.set_position(Gtk.WindowPosition.CENTER)
        self.window.connect("destroy", Gtk.main_quit)

        self.stack = Gtk.Stack()
        self.stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE)
        self.stack.set_transition_duration(180)
        self.window.add(self.stack)

        self.stack.add_named(
            self.make_page(
                "Welcome to GameXOSTR",
                "A fresh, modern desktop for your PC.",
                "Install GameXOSTR, explore the live desktop, or open recovery tools.",
                [
                    ("Next", "go-next", "setup"),
                    ("Recovery tools", "document-revert", "recovery"),
                    ("Use live desktop", "user-desktop", self.close),
                ],
            ),
            "welcome",
        )
        self.stack.add_named(
            self.make_page(
                "Set up GameXOSTR",
                "Choose where GameXOSTR will be installed.",
                "The installer detects internal drives and plugged-in USB drives. Review the selected drive carefully before confirming partition changes.",
                [
                    ("Back", "go-previous", "welcome"),
                    ("Open installer", "system-software-install", self.launch_installer),
                ],
            ),
            "setup",
        )
        self.stack.add_named(
            self.make_page(
                "Recovery tools",
                "Inspect and repair this PC.",
                "The live desktop can be used without installing. Partition Manager can change disks, so use it only when you intend to make repairs.",
                [
                    ("Back", "go-previous", "welcome"),
                    ("Open files", "system-file-manager", self.launch_files),
                    ("Partition Manager", "drive-harddisk", self.launch_partitioner),
                    ("Use live desktop", "user-desktop", self.close),
                ],
            ),
            "recovery",
        )

        self.stack.set_visible_child_name("welcome")
        self.window.show_all()
        self.window.fullscreen()

    def make_page(self, eyebrow, title, description, actions):
        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        outer.set_halign(Gtk.Align.CENTER)
        outer.set_valign(Gtk.Align.CENTER)
        outer.set_margin_start(24)
        outer.set_margin_end(24)

        panel = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=18)
        panel.get_style_context().add_class("panel")
        panel.set_size_request(620, -1)
        panel.set_margin_top(24)
        panel.set_margin_bottom(24)
        panel.set_margin_start(24)
        panel.set_margin_end(24)

        brand = Gtk.Label(label="G A M E X O S T R")
        brand.get_style_context().add_class("brand")
        panel.pack_start(brand, False, False, 0)

        eyebrow_label = Gtk.Label(label=eyebrow.upper())
        eyebrow_label.get_style_context().add_class("eyebrow")
        panel.pack_start(eyebrow_label, False, False, 0)

        title_label = Gtk.Label(label=title)
        title_label.get_style_context().add_class("title")
        title_label.set_line_wrap(True)
        title_label.set_justify(Gtk.Justification.CENTER)
        panel.pack_start(title_label, False, False, 0)

        description_label = Gtk.Label(label=description)
        description_label.get_style_context().add_class("description")
        description_label.set_line_wrap(True)
        description_label.set_max_width_chars(62)
        description_label.set_justify(Gtk.Justification.CENTER)
        panel.pack_start(description_label, False, False, 0)

        actions_box = Gtk.FlowBox()
        actions_box.set_halign(Gtk.Align.CENTER)
        actions_box.set_homogeneous(True)
        actions_box.set_selection_mode(Gtk.SelectionMode.NONE)
        actions_box.set_min_children_per_line(1)
        actions_box.set_max_children_per_line(2)
        actions_box.set_row_spacing(10)
        actions_box.set_column_spacing(10)
        actions_box.set_margin_top(10)
        for label, icon, target in actions:
            button = Gtk.Button.new_with_label(label)
            button.set_size_request(190, 46)
            button.set_image(Gtk.Image.new_from_icon_name(icon, Gtk.IconSize.BUTTON))
            button.set_always_show_image(True)
            button.get_style_context().add_class(
                "primary" if label in ("Next", "Open installer") else "secondary"
            )
            if isinstance(target, str):
                button.connect("clicked", self.show_page, target)
            else:
                button.connect("clicked", lambda _button, callback=target: callback())
            actions_box.add(button)

        panel.pack_start(actions_box, False, False, 0)
        outer.pack_start(panel, False, False, 0)
        return outer

    def show_page(self, _button, page_name):
        self.stack.set_visible_child_name(page_name)

    def launch(self, *command):
        try:
            subprocess.Popen(command)
            self.close()
        except OSError as error:
            dialog = Gtk.MessageDialog(
                transient_for=self.window,
                flags=Gtk.DialogFlags.MODAL,
                message_type=Gtk.MessageType.ERROR,
                buttons=Gtk.ButtonsType.CLOSE,
                text="Could not open that tool",
            )
            dialog.format_secondary_text(str(error))
            dialog.run()
            dialog.destroy()

    def launch_installer(self):
        self.launch("pkexec", "calamares")

    def launch_partitioner(self):
        self.launch("pkexec", "gparted")

    def launch_files(self):
        self.launch("thunar")

    def close(self):
        self.window.destroy()


def load_styles():
    if not CSS_PATH.exists():
        return
    provider = Gtk.CssProvider()
    provider.load_from_path(str(CSS_PATH))
    Gtk.StyleContext.add_provider_for_screen(
        Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
    )


if __name__ == "__main__":
    Gtk.init([])
    load_styles()
    WelcomeWindow()
    Gtk.main()