class GlHParser
    def parse(path)
        data = GlDecl.new

        for line in path.readlines
            func = parse_func(line)
            if func
                data.funcs << func
            end

            const = parse_const(line)
            if const
                data.consts << const
            end
        end

        return data
    end

    def parse_func(line)
        regex = /GL_API\s+([\w* ]+)\s+GL_APIENTRY\s+(\w+)\s*\((.*?)\)/
        m = regex.match(line)
        if ! m
            return nil
        end

        args_str = m[3].strip

        if args_str == "void"
            args = []
        else
            args = args_str.split(",").map {|x|
                parse_func_arg(x)
            }.select {|x| x != nil }
        end

        return {
            name: m[2].strip,
            return: m[1].strip,
            args: args,
            errors: []
        }
    end

    def parse_func_arg(str)
        regex = /^([\w* ]*?)(\w+)$/
        m = regex.match(str.strip)
        if ! m
            return nil
        end
        name = m[2].strip
        type = m[1].strip
        return {
            name: name,
            type: type,
        }
    end

    def parse_const(line)
        regex = /#define\s+(\w+)\s+(\w+)/
        m = regex.match(line.strip)
        if ! m
            return nil
        end

        name = m[1].strip
        value = m[2].strip
        errors = []

        if name == "GL_API"
            return nil
        end

        num_regex = /^[0-9A-Fx]+$/
        m = num_regex.match(value)
        if ! m
            errors << "invalid number: #{value}"
        end

        return {
            name: name,
            value: value,
            errors: errors
        }
    end

end
