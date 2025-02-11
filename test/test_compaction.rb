# frozen_string_literal: true

require "helper"

describe "compaction" do
  def skip_compaction_tests
    # skip if compaction is not supported, or if we're running Ruby 2.7 on windows
    # (because compaction is buggy on that platform)
    !GC.respond_to?(:verify_compaction_references) ||
      (RUBY_VERSION.start_with?("2.7") && Gem.win_platform?)
  end

  describe Nokogiri::XML::Node do
    it "compacts safely" do # https://github.com/sparklemotion/nokogiri/pull/2579
      skip if skip_compaction_tests

      big_doc = "<root>" + ("a".."zz").map { |x| "<#{x}>#{x}</#{x}>" }.join + "</root>"
      doc = Nokogiri.XML(big_doc)

      # ensure a bunch of node objects have been wrapped
      doc.root.children.each(&:inspect)

      # compact the heap and try to get the node wrappers to move
      gc_verify_compaction_references

      # access the node wrappers and make sure they didn't move
      doc.root.children.each(&:inspect)
    end
  end

  describe Nokogiri::XML::Namespace do
    it "namespace_scopes" do
      skip if skip_compaction_tests

      doc = Nokogiri::XML(<<~EOF)
        <root xmlns="http://example.com/root" xmlns:bar="http://example.com/bar">
          <first/>
          <second xmlns="http://example.com/child"/>
          <third xmlns:foo="http://example.com/foo"/>
        </root>
      EOF

      doc.at_xpath("//root:first", "root" => "http://example.com/root").namespace_scopes.inspect

      gc_verify_compaction_references

      doc.at_xpath("//root:first", "root" => "http://example.com/root").namespace_scopes.inspect
    end

    it "remove_namespaces!" do
      skip if skip_compaction_tests

      doc = Nokogiri::XML(<<~XML)
        <root xmlns:a="http://a.flavorjon.es/" xmlns:b="http://b.flavorjon.es/">
          <a:foo>hello from a</a:foo>
          <b:foo>hello from b</b:foo>
          <container xmlns:c="http://c.flavorjon.es/">
            <c:foo c:attr='attr-value'>hello from c</c:foo>
          </container>
        </root>
      XML

      namespaces = doc.root.namespaces
      namespaces.each(&:inspect)
      doc.remove_namespaces!

      gc_verify_compaction_references

      namespaces.each(&:inspect)
    end
  end
end
