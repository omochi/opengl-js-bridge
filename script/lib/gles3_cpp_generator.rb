class Gles3CppFuncDefnGenerator
    attr_reader :func

    def generate_e(func)
        @func = func

        errors = []

        name = func[:name]
        arg_num = self.arg_num
        type = func[:return]

        ls = []

        head = <<EOT
PGE_JS_STATIC_METHOD_DEFN(pge__#{name}) {
    RefPtr<JsValue> e_;
EOT

        ls << head

        if arg_num > 0
            ls << indent(gen_check_arg_num(arg_num), 1)
        end

        i = 0
        while i < arg_num
            arg_get, e = gen_arg_get_e(i)
            errors += e

            ls << indent(arg_get, 1)
            ls << ""
            i += 1
        end

        call = gen_call()
        ls << indent(call, 1)
        ls << ""

        return_, e = gen_return_e(type)
        errors += e
        ls << indent(return_, 1)

        ls << "}"

        ret = ls.join("\n")

        return ret, errors
    end

    def arg_num
        return func[:args].length
    end

    def gen_check_arg_num(arg_num)
        code = <<EOT
if (args.size() != #{arg_num}) {
    auto msg = Format(
        \"[#{func[:name]}] wrong number of arguments (%d for #{arg_num})\",
        static_cast<int>( args.size() ));
    if (e) { *e = JsValue::CreateString(context, msg); }
    return nullptr;
}
EOT
    end

    def gen_arg_get_e(index)
        errors = []
        arg = func[:args][index]
        type = arg[:type]
        arg_name = arg[:name]
        exc_return = "PGE_JS_ERROR_RETHROW(e_, e, e_, nullptr)"

        ls = []

        if GlDecl.is_js_number_type(type)
            ls << "#{type} #{arg_name} = static_cast<#{type}>(args[#{index}]->GetNumberValue(&e_));"
            ls << exc_return
        elsif GlDecl.is_js_typed_array_type(type)
            ls << "#{type} #{arg_name} = static_cast<#{type}>(args[#{index}]->GetTypedArrayPointer(&e_));"
            ls << exc_return
        elsif GlDecl.is_js_string_type(type)
            ls << "std::string #{arg_name}_str = args[#{index}]->GetStringValue(&e_);"
            ls << exc_return
            ls << "#{type} #{arg_name} = #{arg_name}_str.c_str();"
        elsif GlDecl.is_js_boolean_type(type)
            ls << "#{type} #{arg_name} = (args[#{index}]->boolean_value() ? GL_TRUE : GL_FALSE);"
        else
            ls << "#{type} #{arg_name} = ??????;"
            errors << "[CppGen] unknown arg type (#{arg[:name]}: #{type})"
        end

        ret = ls.join("\n")

        return ret, errors
    end

    def gen_arg_get_pointer_or_int_e(index)
        ls = []
        errors = []
        arg = func[:args][index]
        arg_name = arg[:name]
       
        js_name = "js_#{arg_name}"
        js_int_name = "js_#{arg_name}_int"

        source = <<EOT
const GLvoid * #{arg_name} = nullptr;
RefPtr<JsValue> #{js_name} = args[#{index}];
if (#{js_name}->type() == JsValueType::Number) {
    std::intptr_t #{js_int_name} = static_cast<std::intptr_t>(#{js_name}->GetNumberValue(&e_));
    PGE_JS_ERROR_RETHROW(e_, e, e_, nullptr)

    #{arg_name} = reinterpret_cast<const GLvoid *>(#{js_int_name});
} else if(#{js_name}->type() == JsValueType::Object) {
    #{arg_name} = static_cast<const GLvoid *>(#{js_name}->GetTypedArrayPointer(&e_));
    PGE_JS_ERROR_RETHROW(e_, e, e_, nullptr)
}
EOT
        ls << source.rstrip

        ret = ls.join("\n")
        return ret, errors
    end

    def gen_call()
        name = func[:name]
        arg_names = func[:args].map {|x| x[:name] }
        ret_type = func[:return]

        return gen_call_impl(name, arg_names, ret_type)
    end

    def gen_call_impl(name, arg_names, ret_type)
        ls = []

        arg_names_str = arg_names.join(", ")

        if ret_type == "void"
            ls << "#{name}(#{arg_names_str});"
        else
            ls << "#{ret_type} ret = #{name}(#{arg_names_str});"
        end

        ret = ls.join("\n")
        return ret
    end

    def gen_return_e(type)
        ls = []
        errors = []

        js_ret_left = "RefPtr<JsValue> js_ret"

        if type == "void"
            ls << "#{js_ret_left} = JsValue::CreateUndefined(context);"
        else
            if GlDecl.is_js_number_type(type)
                ls << "#{js_ret_left} = JsValue::CreateNumber(context, static_cast<double>(ret));"
            elsif GlDecl.is_js_string_type(type)
                ls << "const char * js_ret_cstr = reinterpret_cast<const char *>(ret);"
                ls << "#{js_ret_left} = JsValue::CreateString(context, std::string(js_ret_cstr));"
            elsif GlDecl.is_js_boolean_type(type)
                ls << "#{js_ret_left} = JsValue::CreateBoolean(context, static_cast<bool>(ret));"
            else
                ls << "#{js_ret_left} = ??????;"
                errors << "[CppGen] unknown return type (#{type})"
            end
        end

        ls << "return js_ret;"

        ret = ls.join("\n")

        return ret, errors
    end
end

class Gles3CppGlShaderSourceDefnGenerator < Gles3CppFuncDefnGenerator
    def arg_num
        2
    end

    def gen_arg_get_e(index)
        if index == 0
            return super(index)
        end
        if index == 1
            ls = []
            errors = []

            source = <<EOT
RefPtr<JsValue> sourcej = args[1];

std::string source_str = sourcej->GetStringValue(&e_);
PGE_JS_ERROR_RETHROW(e_, e, e_, nullptr)

const GLchar * source[] = {
    source_str.c_str()
};
EOT
            ls << source.rstrip
            ret = ls.join("\n")
            return ret, errors
        end
        raise "never"
    end

    def gen_call()
        name = func[:name]
        arg_names = func[:args].map {|x| x[:name] }
        ret_type = func[:return]

        return gen_call_impl("glShaderSource", 
            ["shader", "1", "source", "nullptr"],
            "void")
    end
end

class Gles3CppGlVertexAttribPointerDefnGenerator < Gles3CppFuncDefnGenerator
    def gen_arg_get_e(index)
        if index <= 4
            return super(index)
        end

        return gen_arg_get_pointer_or_int_e(index)
    end
end

class Gles3CppGlDrawElementsDefnGenerator < Gles3CppFuncDefnGenerator
    def gen_arg_get_e(index)
        if index <= 2
            return super(index)
        end

        return gen_arg_get_pointer_or_int_e(index)
    end
end

class Gles3CppGenerator
    def gen_cpp(data)
        ls = []

        code = <<EOT
#include "./gles3_gen.h"

#include "./gles3_internal.h"

using namespace pge;
EOT
        ls << code

        ls << data.valid_funcs.map {|func|
            defn, ers = gen_func_defn_e(func)
            if ers.length != 0
                
                ls2 = ers.map {|er|
                    "// error: #{er}"
                } + [ 
                    "/*",
                    defn,
                    "*/"
                ]

                defn = ls2.join("\n")

                func[:errors].concat(ers)
            end

            defn + "\n"
        }

        return ls.join("\n")
    end

    def gen_install_cpp(data)
        ls = []

        funcs = indent(gen_install_funcs(data), 2)
        consts = indent(gen_install_consts(data), 2)

        code = <<EOT
#include "./gles3_gen.h"

#include "./gles3_internal.h"

namespace pge {
    void JsInstallGles3InstallStaticMethods(JsClassBuilder & b) {
#{funcs}
    }

    void JsInstallGles3InstallConsts(JsValue & clazz,
                                     RefPtr<JsValue> * e)
    {
        RefPtr<JsValue> e_;
        auto context = clazz.context();

#{consts}
    }

    void JsInstallGles3InstallConstsPut(JsValue & clazz,
                                        const char * name,
                                        double value,
                                        RefPtr<JsValue> * e)
    {
        clazz.Set(name, *JsValue::CreateNumber(*clazz.context(), value), e);
    }
}
EOT
        ls << code

        return ls.join("\n")
    end

    def gen_install_funcs(data)
        ls = []
        ls << data.valid_funcs.map {|x|
            name = x[:name]
            "b.AddStaticMethod(\n" +
            "    \"#{name}\",\n"+
            "    PGE_JS_STATIC_METHOD(pge__#{name}));\n"
        }
        return ls.join("\n")
    end

    def gen_install_consts(data)
        ls = []

        ls << data.valid_consts.map {|x|
            name = x[:name]
            value = x[:value]

            code = <<EOT
JsInstallGles3InstallConstsPut(clazz, 
    \"#{name}\",
    static_cast<double>(#{name}),
    &e_);
PGE_JS_ERROR_RETHROW(e_, e, e_,)
EOT
            code
        }

        return ls.join("\n")
    end

    def gen_header(data)
        ls = []

        code = <<EOT
#pragma once

#include "./gles3.h"

#ifdef __cplusplus

namespace pge {
    void JsInstallGles3InstallStaticMethods(JsClassBuilder & builder);
    void JsInstallGles3InstallConsts(JsValue & clazz,
                                     RefPtr<JsValue> * e);
    void JsInstallGles3InstallConstsPut(JsValue & clazz,
                                        const char * name,
                                        double value,
                                        RefPtr<JsValue> * e);
}

#endif
EOT
        ls << code

        ls << data.valid_funcs.map {|x|
            "PGE_JS_STATIC_METHOD_DECL(pge__#{x[:name]});"
        }

        ls << ""

        return ls.join("\n")
    end

    def gen_func_defn_e(func)
        name = func[:name]

        generator = nil
        if name == "glShaderSource"
            generator = Gles3CppGlShaderSourceDefnGenerator.new
        elsif name == "glVertexAttribPointer"
            generator = Gles3CppGlVertexAttribPointerDefnGenerator.new
        elsif name == "glDrawElements"
            generator = Gles3CppGlDrawElementsDefnGenerator.new
        else 
            generator = Gles3CppFuncDefnGenerator.new
        end

        ret, errors = generator.generate_e(func)

        return ret, errors
    end

    def gen_func_decl(func)
        name = func[:name]
        "PGE_JS_STATIC_METHOD_DECL(pge__#{name})"
    end
end
