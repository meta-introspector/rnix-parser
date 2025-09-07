use std::env;
use std::fs;

fn main() {
    // Get the file path from the command-line arguments.
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        eprintln!("Usage: {} <file>", args[0]);
        std::process::exit(1);
    }
    let file_path = &args[1];

    // Read the file content.
    let content = match fs::read_to_string(file_path) {
        Ok(c) => c,
        Err(e) => {
            eprintln!("Error reading file '{}': {}", file_path, e);
            std::process::exit(1);
        }
    };

    // Parse the file using the rnix library.
    let ast = rnix::parse(&content);

    // Print the AST.
    println!("{:#?}", ast.node());

    // Also print any errors found during parsing.
    for error in ast.errors() {
        eprintln!("error: {}", error);
    }
}