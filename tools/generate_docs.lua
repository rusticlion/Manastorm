#!/usr/bin/env lua
-- Script to generate keyword documentation

-- Add manastorm root directory to lua path
package.path = package.path .. ";../?.lua"

-- Import the documentation generator
local DocGenerator = require("docs.keywords")

-- Generate the documentation
DocGenerator.writeDocumentation("../docs/KEYWORDS.md")

print("Documentation generation complete!")