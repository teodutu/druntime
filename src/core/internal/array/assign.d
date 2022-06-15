module core.internal.array.assign;

// Force `enforceRawArraysConformable` to remain weakly `pure`
void enforceRawArraysConformable(const char[] action, const size_t elementSize,
	const void[] a1, const void[] a2) @trusted
{
	import core.internal.util.array : enforceRawArraysConformableNogc;

	alias Type = void function(const char[] action, const size_t elementSize,
		const void[] a1, const void[] a2, in bool allowOverlap = false) @nogc pure nothrow;
	(cast(Type)&enforceRawArraysConformableNogc)(action, elementSize, a1, a2, false);
}

Tarr _d_arrayassign_l(Tarr : T[], T)(return scope Tarr to, scope Tarr from, char* makeWeaklyPure = null) @trusted
{
	pragma(inline, false);
    import core.internal.traits : hasElaborateCopyConstructor;
    import core.lifetime : copyEmplace;
    import core.stdc.string : memcpy;
    import core.stdc.stdint : uintptr_t;

	void[] vFrom = (cast(void*) from.ptr)[0..from.length];
	void[] vTo = (cast(void*) to.ptr)[0..to.length];
	
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

    assert(counter == 4);
    assert(arr1 == arr2);
}

// copy constructor
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

    assert(counter == 4);
    assert(arr1 == arr2);
}

@safe nothrow unittest
{
    // Test that throwing works
    int counter;
    bool didThrow;

    struct Throw
    {
        int val;
        this(this)
        {
            counter++;
            if (counter == 2)
                throw new Exception("");
        }
    }
    try
    {
        Throw[4] a;
        Throw[4] b = [Throw(1), Throw(2), Throw(3), Throw(4)];
        _d_arrayassign_l(a[], b[]);
    }
    catch (Exception)
    {
        didThrow = true;
    }
    assert(didThrow);
    assert(counter == 2);


    // Test that `nothrow` works
    didThrow = false;
    counter = 0;
    struct NoThrow
    {
        int val;
        this(this)
        {
            counter++;
        }
    }
    try
    {
        NoThrow[4] a;
        NoThrow[4] b = [NoThrow(1), NoThrow(2), NoThrow(3), NoThrow(4)];
        _d_arrayassign_l(a[], b[]);
    }
    catch (Exception)
    {
        didThrow = false;
    }
    assert(!didThrow);
    assert(counter == 4);
}

Tarr _d_arrayassign_r(Tarr : T[], T)(return scope Tarr to, scope Tarr from, char* makeWeaklyPure = null) @trusted
{
	pragma(inline, false);
    import core.internal.traits : hasElaborateCopyConstructor;
    import core.lifetime : copyEmplace;
    import core.stdc.string : memcpy;
    import core.stdc.stdint : uintptr_t;

	void[] vFrom = (cast(void*) from.ptr)[0..from.length];
	void[] vTo = (cast(void*) to.ptr)[0..to.length];
	//enforceRawArraysConformable("copy", T.sizeof, vFrom, vTo);

	static if (hasElaborateCopyConstructor!T && is(T == class))
	{
        size_t i;
		for (i = 0; i < to.length; ++i)
			copyEmplace(from[i], to[i]);
	}
	else
	{
		foreach (i; 0 .. to.length)
		{
			void* pdst = vTo.ptr + i * T.sizeof;
			void* psrc = vFrom.ptr + i * T.sizeof;
			memcpy(pdst, psrc, T.sizeof);
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
    _d_arrayassign_r(arr1[], arr2[]);

    assert(counter == 4);
    assert(arr1 == arr2);
}

// copy constructor
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
    _d_arrayassign_r(arr1[], arr2[]);

    assert(counter == 4);
    assert(arr1 == arr2);
}

@safe nothrow unittest
{
    // Test that throwing works
    int counter;
    bool didThrow;

    struct Throw
    {
        int val;
        this(this)
        {
            counter++;
            if (counter == 2)
                throw new Exception("");
        }
    }
    try
    {
        Throw[4] a;
        Throw[4] b = [Throw(1), Throw(2), Throw(3), Throw(4)];
        _d_arrayassign_r(a[], b[]);
    }
    catch (Exception)
    {
        didThrow = true;
    }
    assert(didThrow);
    assert(counter == 2);


    // Test that `nothrow` works
    didThrow = false;
    counter = 0;
    struct NoThrow
    {
        int val;
        this(this)
        {
            counter++;
        }
    }
    try
    {
        NoThrow[4] a;
        NoThrow[4] b = [NoThrow(1), NoThrow(2), NoThrow(3), NoThrow(4)];
        _d_arrayassign_r(a[], b[]);
    }
    catch (Exception)
    {
        didThrow = false;
    }
    assert(!didThrow);
    assert(counter == 4);
}