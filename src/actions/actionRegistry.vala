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
/// A which has knowledge on all possible acion types.
/////////////////////////////////////////////////////////////////////////

public class ActionRegistry : GLib.Object {

    /////////////////////////////////////////////////////////////////////
    /// A list containing all available Action types.
    /////////////////////////////////////////////////////////////////////

    public static Gee.ArrayList<string> types { get; private set; }

    /////////////////////////////////////////////////////////////////////
    /// A map associating a displayable name for each Action,
    /// whether it has a custom icon and a name for the pies.conf
    /// file with it's type.
    /////////////////////////////////////////////////////////////////////

    public static Gee.HashMap<string, TypeDescription?> descriptions { get; private set; }

    /////////////////////////////////////////////////////////////////////
    /// A helper class storing information on a Action type.
    /////////////////////////////////////////////////////////////////////

    public class TypeDescription {
        public string name { get; set; default=""; }
        public string icon { get; set; default=""; }
        public string description { get; set; default=""; }
        public string id { get; set; default=""; }
        public bool icon_name_editable { get; set; default=false; }
    }

    /////////////////////////////////////////////////////////////////////
    /// Registers all Action types.
    /////////////////////////////////////////////////////////////////////

    public static void init() {
        types = new Gee.ArrayList<string>();
        descriptions = new Gee.HashMap<string, TypeDescription?>();

        TypeDescription type_description;

        types.add(typeof(AppAction).name());
        type_description = AppAction.register();
        descriptions.set(typeof(AppAction).name(), type_description);

        types.add(typeof(KeyAction).name());
        type_description = KeyAction.register();
        descriptions.set(typeof(KeyAction).name(), type_description);

        types.add(typeof(PieAction).name());
        type_description = PieAction.register();
        descriptions.set(typeof(PieAction).name(), type_description);

        types.add(typeof(UriAction).name());
        type_description = UriAction.register();
        descriptions.set(typeof(UriAction).name(), type_description);
    }

    /////////////////////////////////////////////////////////////////////
    /// Creates a new Action from the given type name.
    /////////////////////////////////////////////////////////////////////

    public static Action? create_action(string type_id, string name, string icon, string command, bool quickaction) {
        switch (type_id) {
            case "app": return new AppAction(name, icon, command, quickaction);
            case "key": return new KeyAction(name, icon, command, quickaction);
            case "uri": return new UriAction(name, icon, command, quickaction);
            case "pie": return new PieAction(command, quickaction);
        }

        return null;
    }

    /////////////////////////////////////////////////////////////////////
    /// A helper method which creates an Action, appropriate for the
    /// given URI. This can result in an UriAction or in an AppAction,
    /// depending on the Type of the URI.
    /////////////////////////////////////////////////////////////////////

    public static Action? new_for_uri(string uri, string? name = null) {
        var file = GLib.File.new_for_uri(uri);
        var scheme = file.get_uri_scheme();

        string final_icon = "";
        string final_name = file.get_basename();

        switch (scheme) {
            case "application":
                var file_name = uri.split("//")[1];

                var desktop_file = GLib.File.new_for_path("/usr/share/applications/" + file_name);
                if (desktop_file.query_exists())
                    return new_for_desktop_file(desktop_file.get_path());

                break;

            case "trash":
                final_icon = "user-trash";
                final_name = _("Trash");
                break;

            case "http": case "https":
                final_icon = "www";
                final_name = get_domain_name(uri);
                break;

            case "ftp": case "sftp":
                final_icon = "folder-remote";
                final_name = get_domain_name(uri);
                break;

            default:
                try {
                    var info = file.query_info("*", GLib.FileQueryInfoFlags.NONE);

                    if (info.get_content_type() == "application/x-desktop")
                        return new_for_desktop_file(file.get_parse_name());

                    // search for an appropriate icon
                    var icon = info.get_icon();
                    final_icon = Icon.get_icon_name(icon.to_string());

                } catch (GLib.Error e) {
                    warning(e.message);
                }

                break;
        }

        if (!Gtk.IconTheme.get_default().has_icon(final_icon))
                final_icon = "stock_unknown";

        if (name != null)
            final_name = name;

        return new UriAction(final_name, final_icon, uri);
    }

    /////////////////////////////////////////////////////////////////////
    /// A helper method which creates an AppAction for given AppInfo.
    /////////////////////////////////////////////////////////////////////

    public static Action? new_for_app_info(GLib.AppInfo info) {
        // get icon
        var icon = info.get_icon();

        return new AppAction(info.get_display_name(), Icon.get_icon_name(icon.to_string()),
          info.get_commandline());
    }

    /////////////////////////////////////////////////////////////////////
    /// A helper method which creates an AppAction for given *.desktop
    /// file.
    /////////////////////////////////////////////////////////////////////

    public static Action? new_for_desktop_file(string file_name) {
        // check whether its a desktop file to open one of Gnome-Pie's pies
        if (file_name.has_prefix(Paths.launchers)) {
            string id = file_name.substring((long)file_name.length - 11, 3);
            return new PieAction(id);
        }

        var info = new DesktopAppInfo.from_filename(file_name);
        return new_for_app_info(info);
    }

    /////////////////////////////////////////////////////////////////////
    /// A helper method which creates an AppAction for given mime type.
    /////////////////////////////////////////////////////////////////////

    public static Action? default_for_mime_type(string type) {
        var info = AppInfo.get_default_for_type(type, false);
        return new_for_app_info(info);
    }

    /////////////////////////////////////////////////////////////////////
    /// A helper method which creates an AppAction for given uri scheme.
    /////////////////////////////////////////////////////////////////////

    public static Action? default_for_uri(string uri) {
        var info = AppInfo.get_default_for_uri_scheme(uri);
        return new_for_app_info(info);
    }

    /////////////////////////////////////////////////////////////////////
    /// Returns for example www.google.com when http://www.google.de/?q=h
    /// is given.
    /////////////////////////////////////////////////////////////////////

    private static string get_domain_name(string url) {
        int domain_end = url.index_of_char('/', 7);
        int domain_begin = url.index_of_char('/', 0) + 2;

        if (domain_begin < domain_end) return url.substring(domain_begin, domain_end-domain_begin);

        return url;
    }
}

}
