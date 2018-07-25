require_relative "gl_decl"
require_relative "gl_h_parser"
require_relative "gl_mac_filter"
require_relative "gles3_cpp_generator"
require_relative "gles3_ts_generator"

class Gles3Driver
    def run(header, cpp_out, ts_out)
        parser = GlHParser.new
        mac_filter = GlMacFilter.new
        cpp_gen = Gles3CppGenerator.new
        ts_gen = Gles3TsGenerator.new

        data = parser.parse(header)

        mac_filter.filter(data)

        code = cpp_gen.gen_cpp(data)
        (cpp_out + "gles3_gen.cpp").write(code)

        code = cpp_gen.gen_install_cpp(data)
        (cpp_out + "gles3_gen_install.cpp").write(code)

        code = cpp_gen.gen_header(data)
        (cpp_out + "gles3_gen.h").write(code)

        code = ts_gen.gen_ts(data)
        (ts_out + "Gles3.ts").write(code)

        data.dump_errors
    end
end


