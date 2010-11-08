open Printf
open Http
open Log
open Lwt

let md_file f =
  let f = match Filesystem_templates.t f with |Some x -> x |None -> "" in
  let md = Markdown.parse_text f in
  Markdown_html.t md

let md_xml f =
  let ibuf = Htcaml.Html.to_string (md_file f) in
  ibuf
 
let col_files l r = 
  let h = <:html< 
     <div class="left_column">
       <div class="summary_information"> $md_file l$ </>
     </>
     <div class="right_column"> $md_file r$ </>
  >> in 
  Htcaml.Html.to_string h 

module Index = struct
  let body = col_files "intro.md" "ne.md"
  let t = Template.t "index" body
end

module Resources = struct
  let body = col_files "docs.md" "papers.md"
  let t = Template.t "resources" body
end 

module About = struct
  let body = col_files "status.md" "ne.md"
  let t = Template.t "about" body
end

module Blog = struct
  open Blog
  let html_of_ent e =
    let author = match e.author.Atom.uri with
      |None -> <:html< $str:e.author.Atom.name$ >>
      |Some uri -> <:html< <a href= $str:uri$ > $str:e.author.Atom.name$ </> >> in
    let tags = List.map (fun t -> 
      <:html< <span class="blog_tag"> $str:t$ </> >>) e.tags in
    let day,month,year,hour,minute = e.updated in
    <:html<
      <div class="blog_entry_heading">
        <div class="blog_entry_title">
          $str:e.subject$
        </>
        <div class="blog_entry_info">
          <i> Posted by $author$ on
          $str:sprintf "%2d/%2d/%4d" day month year$
          </>
        </>
      </>
      <div class="blog_entry_body"> $md_file e.body$ </>
    >>

  let entries = List.sort compare (List.map html_of_ent Blog.entries)

  let right_bar = Blog.bar
  let body = <:html<
    <div class="left_column_blog">
      <div class="summary_information">
        $list:entries$
       </>
    </>
    <div class="right_column_blog">
       $list:right_bar$
    </>
  >>

  let idx = Template.t "blog" (Htcaml.Html.to_string body)
  let atom_feed = 
    let f = Blog.atom_feed md_xml Blog.entries in
    Atom.string_of_feed f

  let t = function
   |[] -> idx
   |["atom.xml"] -> atom_feed
end

