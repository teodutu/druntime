module core.internal.array.assign;

Tarr _d_arrayassign_l(Tarr : T[], T)(return scope Tarr to, scope Tarr from, char* makeWeaklyPure = null) @trusted
{
	pragma(inline, false);
    import core.internal.traits : hasElaborateCopyConstructor;
    import core.lifetime : copyEmplace;
    import core.stdc.string : memcpy;
    import core.stdc.stdint : uintptr_t;

	void[] vFrom = (cast(void*) from.ptr)[0..from.length];
	void[] vTo = (cast(void*) to.ptr)[0..to.length];

	// Force `enforceRawArraysConformable` to remain weakly `pure`
	void enforceRawArraysConformable(const char[] action, const size_t elementSize,
		const void[] a1, const void[] a2) @trusted
	{
		import core.internal.util.array : enforceRawArraysConformableNogc;

		alias Type = void function(const char[] action, const size_t elementSize,
			const void[] a1, const void[] a2, in bool allowOverlap = false) @nogc pure nothrow;
		(cast(Type)&enforceRawArraysConformableNogc)(action, elementSize, a1, a2, false);
	}

	enforceRawArraysConformable("copy", T.sizeof, vFrom, vTo);

	static if (hasElaborateCopyConstructor!T)
	{
		if (vFrom.ptr < vTo.ptr && vTo.ptr < vFrom.ptr + T.sizeof * vFrom.length)
		{
			for (auto i = to.length; i--; )
				copyEmplace(from[i], to[i]);
		}
		else
		{
			for (auto i = 0; i < to.length; ++i)
				copyEmplace(from[i], to[i]);
		}
	}
	else
	{
		if (vFrom.ptr < vTo.ptr && vTo.ptr < vFrom.ptr + T.sizeof * vFrom.length)
		{
			for (auto i = to.length; i--; )
			{
				void* pdst = vTo.ptr + i * T.sizeof;
				void* psrc = vFrom.ptr + i * T.sizeof;
				memcpy(pdst, psrc, T.sizeof);
			}
		}
		else
		{
			memcpy(cast(void*) to.ptr, from.ptr, to.length * T.sizeof);
		}
	}

	return to;
}

@safe unittest
{
    int counter;
    struct S
    {
        int val;
        this(int val) { this.val = val; }
        this(const scope ref S rhs)
        {
            val = rhs.val;
            counter++;
        }
    }

    S[4] arr1;
    S[4] arr2 = [S(0), S(1), S(2), S(3)];
    _d_arrayassign_l(arr1[], arr2[]);

		pragma(msg, "=========== hei man ==============");
    assert(counter == 4);
    assert(arr1 == arr2);
		pragma(msg, "========== hello ================");
}