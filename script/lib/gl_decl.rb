class GlDecl
    def initialize
        @funcs = []
        @consts = []
    end

    attr_reader :funcs
    attr_reader :consts

    def valid_funcs
        funcs.select {|x| x[:errors].length == 0 }
    end

    def valid_consts
        consts.select {|x| x[:errors].length == 0 }
    end

    def dump_errors
        for func in funcs
            if func[:errors].length > 0
                puts "#{func[:name]}"
                for er in func[:errors]
                    puts "  #{er}"
                end
            end
        end
        for const in consts
            if const[:errors].length > 0
                puts "#{const[:name]}"
                for er in const[:errors]
                    puts "  #{er}"
                end
            end
        end
    end

    def self.gl_alias_types()
        [
            "GLsizeiptr",
            "GLintptr",
            "GLint",
            "GLuint",
            "GLsizei",
            "GLenum",
            "GLbitfield",
            "GLfloat",
            "GLclampf",
            "GLboolean"
        ]
    end

    def self.is_js_number_type(type)
        [
            "GLsizeiptr",
            "GLintptr",
            "GLint",
            "GLuint",
            "GLsizei",
            "GLenum",
            "GLbitfield",
            "GLfloat",
            "GLclampf",
            "int"
        ].include?(type)
    end

    def self.is_js_string_type(type)
        [
            "const GLchar *",
            "const GLchar*",
            "const GLubyte*"
        ].include?(type)
    end

    def self.is_js_boolean_type(type)
        [
            "GLboolean"
        ].include?(type)
    end

    def self.is_js_void_type(type)
        [
            "void"
        ].include?(type)
    end

    def self.is_js_typed_array_type(type)
        is_js_int8_array_type(type) ||
        is_js_uint8_array_type(type) ||
        is_js_int32_array_type(type) ||
        is_js_uint32_array_type(type) ||
        is_js_float32_array_type(type)
    end

    def self.is_js_int8_array_type(type)
        [
            "GLboolean*"
        ].include?(type)
    end

    def self.is_js_uint8_array_type(type)
        [
            "const GLvoid*",
            "GLvoid*",
            "GLchar*",
        ].include?(type)
    end

    def self.is_js_int32_array_type(type)
        [
            "const GLint*",
            "GLint*",
            "const GLenum*",
            "GLenum*",
        ].include?(type)
    end

    def self.is_js_uint32_array_type(type)
        [
            "const GLuint*",
            "GLuint*",
            "GLsizei*",
        ].include?(type)
    end

    def self.is_js_float32_array_type(type)
        [
            "const GLfloat*",
            "GLfloat*",
        ].include?(type)
    end

    def self.type_to_js_type(type)
        if GlDecl.gl_alias_types().include?(type)
            return type
        elsif GlDecl.is_js_number_type(type)
            return "number"
        elsif GlDecl.is_js_string_type(type)
            return "string"
        elsif GlDecl.is_js_boolean_type(type)
            return "boolean"
        elsif GlDecl.is_js_void_type(type)
            return "void"
        elsif GlDecl.is_js_int8_array_type(type)
            return "Int8Array"
        elsif GlDecl.is_js_uint8_array_type(type)
            return "Uint8Array"
        elsif GlDecl.is_js_int32_array_type(type)
            return "Int32Array"
        elsif GlDecl.is_js_uint32_array_type(type)
            return "Uint32Array"
        elsif GlDecl.is_js_float32_array_type(type)
            return "Float32Array"
        else
            return nil
        end
    end
end
