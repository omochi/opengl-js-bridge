class GlMacFilter
	attr_reader :invalid_const_names
	attr_reader :invalid_func_names
	def initialize
		@invalid_const_names = [
			"GL_ES_VERSION_3_0",
			"GL_ES_VERSION_2_0",
			"GL_ALIASED_POINT_SIZE_RANGE",
			"GL_RED_BITS",
			"GL_GREEN_BITS",
			"GL_BLUE_BITS",
			"GL_ALPHA_BITS",
			"GL_DEPTH_BITS",
			"GL_STENCIL_BITS",
			"GL_GENERATE_MIPMAP_HINT",
			"GL_LUMINANCE",
			"GL_LUMINANCE_ALPHA",
			"GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS",
			"GL_PRIMITIVE_RESTART_FIXED_INDEX",
			"GL_ANY_SAMPLES_PASSED_CONSERVATIVE",
			"GL_TRANSFORM_FEEDBACK_PAUSED",
			"GL_TRANSFORM_FEEDBACK_ACTIVE",
			"GL_COMPRESSED_R11_EAC",
			"GL_COMPRESSED_SIGNED_R11_EAC",
			"GL_COMPRESSED_RG11_EAC",
			"GL_COMPRESSED_SIGNED_RG11_EAC",
			"GL_COMPRESSED_RGB8_ETC2",
			"GL_COMPRESSED_SRGB8_ETC2",
			"GL_COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2",
			"GL_COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2",
			"GL_COMPRESSED_RGBA8_ETC2_EAC",
			"GL_COMPRESSED_SRGB8_ALPHA8_ETC2_EAC",
			"GL_TEXTURE_IMMUTABLE_FORMAT",
			"GL_MAX_ELEMENT_INDEX",
			"GL_NUM_SAMPLE_COUNTS",
			"GL_TEXTURE_IMMUTABLE_LEVELS"
		]
		@invalid_func_names = [
			"glInvalidateFramebuffer",
			"glInvalidateSubFramebuffer",
			"glTexStorage2D",
			"glTexStorage3D",
			"glGetInternalformativ"
		]
	end
	def filter(data)
		for const in data.consts
			if invalid_const_names.include?(const[:name])
				const[:errors] << "[MacFilter] unsupported by mac: #{const[:name]}"
			end
		end
		for func in data.funcs
			if invalid_func_names.include?(func[:name])
				func[:errors] << "[MacFilter] unsupported by mac: #{func[:name]}"
			end
		end
	end
end