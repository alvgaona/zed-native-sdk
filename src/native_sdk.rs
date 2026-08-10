use zed::settings::LspSettings;
use zed_extension_api::{self as zed, LanguageServerId, Result};

const BINARY_NAME: &str = "native";

const LOCAL_BINARY: &str = "node_modules/.bin/native";

/// The worktree's own CLI, if the project installed one. There is no existence check in the
/// extension API, so a successful read is the test.
fn local_binary(worktree: &zed::Worktree) -> Option<String> {
    worktree
        .read_text_file(LOCAL_BINARY)
        .ok()
        .map(|_| format!("{}/{LOCAL_BINARY}", worktree.root_path()))
}

struct NativeSdkExtension;

impl zed::Extension for NativeSdkExtension {
    fn new() -> Self {
        Self
    }

    fn language_server_command(
        &mut self,
        _language_server_id: &LanguageServerId,
        worktree: &zed::Worktree,
    ) -> Result<zed::Command> {
        // The server is a subcommand of the SDK's own CLI, so there is nothing to download and
        // nothing to keep in sync — whichever `native` the project builds with is the one that
        // checks the markup.
        //
        // A project-local install wins over the global one: an app that pins @native-sdk/cli as a
        // dependency should be checked by the version it pins, not by whatever is on PATH.
        let command = local_binary(worktree)
            .or_else(|| worktree.which(BINARY_NAME))
            .ok_or_else(|| {
                // Highlighting does not depend on this, so say so — otherwise the failure reads
                // like the extension is broken to someone who just opened a .native file.
                "the `native` CLI was not found, so diagnostics, hover and completion are off \
                 (highlighting is unaffected). Install it with `bun add -g @native-sdk/cli`."
                    .to_string()
            })?;

        Ok(zed::Command {
            command,
            args: vec!["markup".to_string(), "lsp".to_string()],
            env: Default::default(),
        })
    }

    fn language_server_workspace_configuration(
        &mut self,
        server_id: &LanguageServerId,
        worktree: &zed::Worktree,
    ) -> Result<Option<zed::serde_json::Value>> {
        LspSettings::for_worktree(server_id.as_ref(), worktree).map(|settings| settings.settings)
    }
}

zed::register_extension!(NativeSdkExtension);
