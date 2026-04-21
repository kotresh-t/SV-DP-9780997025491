/************************************************
* Composite Pattern example for a filesystem.
* Roles:
* 1. Component : FileSystemComponent
* 2. Leaf      : FileLeaf
* 3. Composite : Directory
************************************************/
/* Results: 
# Filesystem hierarchy using Composite Pattern:
# + Directory : root
#   + Directory : docs
#     - File      : README.txt
#     - File      : notes.md
#   + Directory : config
#     - File      : settings.ini
#   - File      : top_level.log
*/

module tb;

  virtual class FileSystemComponent;
    protected string name;

    function new(string name);
      this.name = name;
    endfunction

    function string get_name();
      return name;
    endfunction

    pure virtual function void show_details(string indent = "");
  endclass : FileSystemComponent


  class FileLeaf extends FileSystemComponent;
    function new(string name);
      super.new(name);
    endfunction

    virtual function void show_details(string indent = "");
      $display("%s- File      : %s", indent, name);
    endfunction
  endclass : FileLeaf


  class Directory extends FileSystemComponent;
    FileSystemComponent children[$];

    function new(string name);
      super.new(name);
    endfunction

    function void add(FileSystemComponent child);
      children.push_back(child);
    endfunction

    virtual function void show_details(string indent = "");
      $display("%s+ Directory : %s", indent, name);
      foreach (children[i]) begin
        children[i].show_details({indent, "  "});
      end
    endfunction
  endclass : Directory


  initial begin
    FileLeaf   file_readme;
    FileLeaf   file_config;
    FileLeaf   file_notes;
    FileLeaf   file_log;
    Directory  docs_dir;
    Directory  cfg_dir;
    Directory  root_dir;

    file_readme = new("README.txt");
    file_config = new("settings.ini");
    file_notes  = new("notes.md");
    file_log    = new("top_level.log");

    docs_dir = new("docs");
    cfg_dir  = new("config");
    root_dir = new("root");

    docs_dir.add(file_readme);
    docs_dir.add(file_notes);
    cfg_dir.add(file_config);

    root_dir.add(docs_dir);
    root_dir.add(cfg_dir);
    root_dir.add(file_log);

    $display("Filesystem hierarchy using Composite Pattern:");
    root_dir.show_details();
  end

endmodule : tb
