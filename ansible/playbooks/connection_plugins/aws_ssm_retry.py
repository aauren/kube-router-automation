# Thin wrapper around amazon.aws.aws_ssm that papers over two upstream bugs that bite us whenever the SSM agent
# goes away mid-play (agent auto-update, reboot module). See the methods below for the specifics.
from __future__ import annotations

from ansible_collections.amazon.aws.plugins.connection.aws_ssm import DOCUMENTATION  # noqa: F401 # Ansible reads option defs from this
from ansible_collections.amazon.aws.plugins.connection.aws_ssm import Connection as _SSMConnection


class Connection(_SSMConnection):
    # Upstream reads reconnection_retries in __init__, before Ansible has pushed host vars into the plugin via
    # set_options(), so the ssm_retry decorator always sees the default of 3 (~4s of backoff)
    def set_options(self, *args, **kwargs):
        super().set_options(*args, **kwargs)
        self.reconnection_retries = self.get_option("reconnection_retries")

    # If the instance drops mid-command, terminate_session() raises ValidationException (only ReferenceError is
    # caught upstream) and close() bails before clearing session_manager. Every later reset() then calls
    # communicate() on the same dead process and fails with "Cannot send input after starting communication".
    def close(self):
        try:
            super().close()
        except Exception as e:  # noqa: BLE001 # We're throwing the session away regardless of why terminate failed
            self.verbosity_display(3, f"ignoring error while terminating SSM session: {e}")
        finally:
            self.session_manager = None
            self._connected = False
