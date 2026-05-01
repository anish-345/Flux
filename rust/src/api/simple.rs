/// Initialise flutter_rust_bridge default utilities.
/// This function MUST exist and be annotated with `#[flutter_rust_bridge::frb(init)]`.
#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}
