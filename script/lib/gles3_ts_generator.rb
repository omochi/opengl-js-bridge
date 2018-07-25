class Gles3TsFuncGenerator
    attr_reader :func
    def generate_e(func)
        @func = func

        errors = []
        name = func[:name]
        type = func[:return]
        args = []
        js_type = nil

        args = []
        for index in 0...arg_num
            arg, ers = gen_func_arg_e(index)
            errors.concat(ers)
            args << arg
        end


        js_type, ers = type_to_js_type_e(type)
        errors.concat(ers)
    
        args_str = args.join(", ")
        ret = "#{name}(#{args_str}): #{js_type};"
        return ret, errors
    end

    def arg_num
        return func[:args].length
    end

    def gen_func_arg_e(index)
        errors = []
        arg = func[:args][index]
        type = arg[:type]

        js_type, ers = type_to_js_type_e(type)
        errors.concat(ers)

        ret = "#{arg[:name]}: #{js_type}"
        return ret, errors
    end

    def type_to_js_type_e(type)
        errors = []
        js_type = GlDecl.type_to_js_type(type)
        if ! js_type
            js_type = "???"
            errors << "[TsGen] unknown return type: #{type}"
        end
        return js_type, errors
    end
end

class Gles3TsGlShaderSourceGenerator < Gles3TsFuncGenerator
    def arg_num
        2
    end

    def gen_func_arg_e(index)
        if index == 0
            return super(index)
        end
        if index == 1
            ers = []
            ret = "source: string"
            return ret, ers
        end
        raise "never"
    end
end

class Gles3TsGlVertexAttribPointerGenerator < Gles3TsFuncGenerator
    def gen_func_arg_e(index)
        if index <= 4
            return super(index)
        end

        errors = []

        name = func[:args][index][:name]
        ret = "#{name}: number | Uint8Array"
        return ret, errors
    end
end

class Gles3TsGlDrawElementsGenerator < Gles3TsFuncGenerator
    def gen_func_arg_e(index)
        if index <= 2
            return super(index)
        end

        errors = []

        name = func[:args][index][:name]
        ret = "#{name}: number | Uint8Array"
        return ret, errors
    end
end

class Gles3TsGenerator

    def gen_ts(data)
        ls = []

        types_lines = []
        for type in GlDecl.gl_alias_types()
            js_type = nil
            if GlDecl.is_js_number_type(type)
                js_type = "number"
            elsif GlDecl.is_js_boolean_type(type)
                js_type = "boolean"
            end

            if js_type
                types_lines << "export type #{type} = #{js_type};"
            end
        end

        types = types_lines.join("\n") + "\n"

        body = indent(gen_ts_body(data), 1)

        code = <<EOT
import { PgeNative } from "../../PgeNative";

declare const __pgeNative: PgeNative;

#{types}
export interface Gles3Static {
#{body}
}

export let Gles3: Gles3Static;
if (typeof __pgeNative != "undefined") {
    Gles3 = __pgeNative.Gles3;
}
EOT

        ls << code

        return ls.join("\n")
    end

    def gen_ts_body(data)
        ls = []

        ls << data.valid_consts.map {|x|
            "readonly #{x[:name]}: number;"
        }
        ls << ""
        ls << data.valid_funcs.map {|x|
            f, ers = gen_ts_func_e(x)
            x[:errors].concat(ers)
            f
        }

        return ls.join("\n")
    end

    def gen_ts_func_e(func)
        generator = nil

    	name = func[:name]
        if name == "glShaderSource"
            generator = Gles3TsGlShaderSourceGenerator.new
        elsif name == "glVertexAttribPointer"
            generator = Gles3TsGlVertexAttribPointerGenerator.new
        elsif name == "glDrawElements"
            generator = Gles3TsGlDrawElementsGenerator.new
        else
            generator = Gles3TsFuncGenerator.new
        end

        return generator.generate_e(func)
    end


end