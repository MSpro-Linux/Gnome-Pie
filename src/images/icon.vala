/////////////////////////////////////////////////////////////////////////
// Copyright (c) 2011-2016 by Simon Schneegans
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or (at
// your option) any later version.
//
// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
/////////////////////////////////////////////////////////////////////////

namespace GnomePie {

/////////////////////////////////////////////////////////////////////////
///  A class representing a square-shaped icon, loaded from the users
/// icon theme.
/////////////////////////////////////////////////////////////////////////

public class Icon : Image {

    /////////////////////////////////////////////////////////////////////
    /// A cache which stores loaded icon. It is cleared when the icon
    /// theme of the user changes. The key is in form <filename>@<size>.
    /////////////////////////////////////////////////////////////////////

    private static Gee.HashMap<string, Cairo.ImageSurface?> cache { private get; private set; }

    /////////////////////////////////////////////////////////////////////
    /// Initializes the cache.
    /////////////////////////////////////////////////////////////////////

    public static void init() {
        clear_cache();

        Gtk.IconTheme.get_default().changed.connect(() => {
            clear_cache();
        });
    }

    /////////////////////////////////////////////////////////////////////
    /// Clears the cache.
    /////////////////////////////////////////////////////////////////////

    public static void clear_cache() {
        cache = new Gee.HashMap<string, Cairo.ImageSurface?>();
    }

    /////////////////////////////////////////////////////////////////////
    /// Loads an icon from the current icon theme of the user.
    /////////////////////////////////////////////////////////////////////

    public Icon(string icon_name, int size) {
        var cached = Icon.cache.get("%s@%u".printf(icon_name, size));

        if (cached == null) {
            this.load_file_at_size(Icon.get_icon_file(icon_name, size), size, size);
            Icon.cache.set("%s@%u".printf(icon_name, size), this.surface);
        } else {
            this.surface = cached;
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Returns the size of the icon in pixels. Greetings to Liskov.
    /////////////////////////////////////////////////////////////////////

    public int size() {
        return base.width();
    }

    /////////////////////////////////////////////////////////////////////
    /// Returns the icon name for a given GLib.Icon.
    /////////////////////////////////////////////////////////////////////

    public static string get_icon_name(string? icon) {
        if (icon != null) {
            var icon_names = icon.down().split(" ");

            foreach (var icon_name in icon_names) {
                if (Gtk.IconTheme.get_default().has_icon(icon_name)) {
                    return icon_name;
                }
            }
        }

        return "";
    }

    /////////////////////////////////////////////////////////////////////
    /// Returns the filename for a given system icon.
    /////////////////////////////////////////////////////////////////////

    public static string get_icon_file(string icon_name, int size) {
        string result = "";

        if (icon_name.contains("/")) {
            var file = GLib.File.new_for_path(icon_name);
            if(file.query_exists())
                return icon_name;

            warning("Icon \"" + icon_name + "\" not found! Using default icon...");
        }


        var icon_theme = Gtk.IconTheme.get_default();
        var file = icon_theme.lookup_icon(icon_name, size, 0);
        if (file != null) result = file.get_filename();

        if (result == "") {
            warning("Icon \"" + icon_name + "\" not found! Using default icon...");

            string[] default_icons = {"application-default-icon", "stock_unknown"};
            foreach (var icon in default_icons) {
                file = icon_theme.lookup_icon(icon, size, 0);
                if (file != null) {
                    result = file.get_filename();
                    break;
                }
            }

            if (result == "")
                warning("No default icon found! Will be ugly...");
        }

        return result;
    }
}

}
