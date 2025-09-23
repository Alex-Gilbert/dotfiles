#!/usr/bin/env python3
# Minimal org.freedesktop.FileManager1 shim → opens Kitty + yazi on requested items
import asyncio, os, subprocess, sys, urllib.parse
from dbus_next.aio import MessageBus
from dbus_next.service import ServiceInterface, method, dbus_property, PropertyAccess

TERMINAL = os.environ.get("YAZI_TERMINAL", "kitty")
YAZI = os.environ.get("YAZI_BIN", "yazi")

def uri_to_path(uri: str) -> str:
    if uri.startswith("file://"):
        return urllib.parse.unquote(uri.replace("file://", "", 1))
    return uri

class FM1(ServiceInterface):
    def __init__(self):
        super().__init__("org.freedesktop.FileManager1")

    @method()
    def ShowItems(self, uris: 'as', startup_id: 's'):
        paths = [uri_to_path(u) for u in uris]
        target = paths[0] if paths else os.path.expanduser("~")
        subprocess.Popen([TERMINAL, "-e", YAZI, target])
        return

    @method()
    def ShowFolders(self, uris: 'as', startup_id: 's'):
        return self.ShowItems(uris, startup_id)

    @method()
    def ShowItemProperties(self, uris: 'as', startup_id: 's'):
        return self.ShowItems(uris, startup_id)

    @dbus_property(access=PropertyAccess.READ)
    def Version(self) -> 's':
        return "1.0"

async def main():
    bus = await MessageBus().connect()
    await bus.request_name("org.freedesktop.FileManager1")
    bus.export("/org/freedesktop/FileManager1", FM1())
    print("yazi-fm1 ready", file=sys.stderr)
    await asyncio.get_running_loop().create_future()

if __name__ == "__main__":
    asyncio.run(main())
