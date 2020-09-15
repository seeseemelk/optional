module tests.optional;

import optional.optional;

import std.meta: AliasSeq;
import std.stdio: writeln;
import std.algorithm: equal;

alias QualifiedAlisesOf(T) = AliasSeq!(T, const T, immutable T);
alias OptionalsOfQualified(T) = AliasSeq!(Optional!T, Optional!(const T), Optional!(immutable T));
alias QualifiedOptionalsOfQualified(T) = AliasSeq!(QualifiedAlisesOf!(Optional!T), OptionalsOfQualified!T);

private enum isObject(T) = is(T == class) || is(T == interface);

import std.range, std.traits;

@("Should allow equalify with all qualifiers")
@nogc @safe unittest {
    foreach (T; QualifiedOptionalsOfQualified!int) {
        auto a = T();
        auto b = T(3);
        auto c = T(4);
        assert(a == none);
        assert(b == b);
        assert(b != c);
        assert(c == 4);
    }
}

@("Should wotk with opUnary, opBinary, and opRightBinary")
@nogc @safe unittest {
    import std.meta: AliasSeq;
    import std.traits: isMutable;
    import std.range: ElementType;
    foreach (T; QualifiedOptionalsOfQualified!int) {
        T a = 10;
        T b = none;
        static assert(!__traits(compiles, { int x = a; }));
        static assert(!__traits(compiles, { void func(int n){} func(a); }));
        assert(a == 10);
        assert(b == none);
        assert(a != 20);
        assert(a != none);
        assert((+a) == some(10));
        assert((-b) == none);
        assert((-a) == some(-10));
        assert((+b) == none);
        assert((-b) == none);
        assert((a + 10) == some(20));
        assert((b + 10) == none);
        assert((a - 5) == some(5));
        assert((b - 5) == none);
        assert((a * 20) == some(200));
        assert((b * 20) == none);
        assert((a / 2) == some(5));
        assert((b / 2) == none);
        assert((10 + a) == some(20));
        assert((10 + b) == none);
        assert((15 - a) == some(5));
        assert((15 - b) == none);
        assert((20 * a) == some(200));
        assert((20 * b) == none);
        assert((50 / a) == some(5));
        assert((50 / b) == none);
        static if (isMutable!(ElementType!T) && isMutable!(T)) {
            assert((++a) == some(11));
            assert((a++) == some(11));
            assert(a == some(12));
            assert((--a) == some(11));
            assert((a--) == some(11));
            assert(a == some(10));
            a = a;
            assert(a == some(10));
            a = 20;
            assert(a == some(20));
        } else {
            static assert(!__traits(compiles, { ++a; }));
            static assert(!__traits(compiles, { a++; }));
            static assert(!__traits(compiles, { --a; }));
            static assert(!__traits(compiles, { a--; }));
            static assert(!__traits(compiles, { a = a; }));
            static assert(!__traits(compiles, { a = 20; }));
        }
    }
}

@("Should be mappable")
@safe unittest {
    import std.algorithm: map;
    import std.conv: to;
    auto a = some(10);
    auto b = no!int;
    assert(a.map!(to!double).equal([10.0]));
    assert(b.map!(to!double).empty);
}

@("Should have opBinary return an optional")
@nogc @safe unittest {
    auto a = some(3);
    assert(a + 3 == some(6));
    auto b = no!int;
    assert(b + 3 == none);
}


@("Should allow equality and opAssign between all qualified combinations")
@nogc @safe unittest {
    import std.meta: AliasSeq;

    alias U = int;
    alias T = Optional!U;
    immutable U other = 4;

    alias Constructors = AliasSeq!(
        AliasSeq!(
            () => T(),
            () => const T(),
            () => immutable T(),
            () => T(U.init),
            () => const T(U.init),
            () => immutable T(U.init),
        ),
        AliasSeq!(
            () => no!U,
            () => no!(const U),
            () => no!(immutable U),
            () => some!U(U.init),
            () => some!(const U)(U.init),
            () => some!(immutable U)(U.init),
        )
    );

    static foreach (I; 0 .. 2) {{
        auto nm = Constructors[I * 6 + 0]();
        auto nc = Constructors[I * 6 + 1]();
        auto ni = Constructors[I * 6 + 2]();
        auto sm = Constructors[I * 6 + 3]();
        auto sc = Constructors[I * 6 + 4]();
        auto si = Constructors[I * 6 + 5]();

        assert(sm != nm);
        assert(sm != nc);
        assert(sm != ni);
        assert(sc != nm);
        assert(sc != nc);
        assert(sc != ni);
        assert(si != nm);
        assert(si != nc);
        assert(si != ni);

        assert(sm == sc);
        assert(sm == si);
        assert(sc == si);

        assert(nm == nc);
        assert(nm == ni);
        assert(nc == ni);

        sm = other;
        nm = other;
        assert(sm == nm);

        static assert( __traits(compiles, nm = other));
        static assert(!__traits(compiles, ni = other));
        static assert(!__traits(compiles, nc = other));
        static assert( __traits(compiles, sm = other));
        static assert(!__traits(compiles, si = other));
        static assert(!__traits(compiles, sc = other));
    }}
}

@("Should not allow properties of type to be reachable")
@nogc @safe unittest {
    static assert(!__traits(compiles, some(3).max));
    static assert(!__traits(compiles, some(some(3)).max));
}

@("Should be filterable")
@safe unittest {
    import std.algorithm: filter;
    import std.range: array;
    foreach (T; QualifiedOptionalsOfQualified!int) {
        const arr = [
            T(),
            T(3),
            T(),
            T(7),
        ];
        assert(arr.filter!(a => a != none).array == [some(3), some(7)]);
    }
}

@("Should print like a range")
unittest {
    assert(no!int.toString == "[]");
    assert(some(3).toString == "[3]");

    static class A {
        override string toString() { return "Yo"; }
        string toString() const { return "Yo"; }
    }
    Object a = new A;

    assert(some(cast(A)a).toString == "[Yo]");
    assert(some(cast(const A)a).toString == "[Yo]");
}

@("Should print out const optional")
@safe unittest {
    const a = some(3);
    assert(a.toString == "[3]");
}

@("Should be joinerable and eachable")
@safe unittest {
    import std.uni: toUpper;
    import std.range: only;
    import std.algorithm: joiner, map, each;

    static maybeValues = only(no!string, some("hello"), some("world"));
    assert(maybeValues.joiner.map!toUpper.joiner(" ").equal("HELLO WORLD"));

    static moreValues = only(some("hello"), some("world"), no!string);
    uint count = 0;
    foreach (value; moreValues.joiner) ++count;
    assert(count == 2);
    moreValues.joiner.each!(value => ++count);
    assert(count == 4);
}

@("Should not allow assignment to const")
@nogc @safe unittest {
    Optional!(const int) opt = Optional!(const int)(42);
    static assert(!__traits(compiles, opt = some(24)));
    static assert(!__traits(compiles, opt = none));
}

@("Should treat null as valid values for pointer types")
@nogc @safe unittest {
    auto a = no!(int*);
    auto b = *a;
    assert(a == no!(int*));
    assert(b == no!(int));
    b = 3;
    assert(b == some(3));
    a = null;
    assert(a == some!(int*)(null));
    assert(*a == no!int);
}

@("Should not allow assignment to immutable")
@nogc @safe unittest {
    auto a = some!(immutable int)(1);
    static assert(!__traits(compiles, { a = 2; }));
}

@("Should forward to opCall if callable")
@nogc @safe unittest {
    int f0(int) { return 4; }
    alias A = typeof(&f0);
    auto a0 = some(&f0);
    auto a1 = no!A;
    assert(a0(3) == some(4));
    assert(a1(3) == no!int);

    void f1() {}
    alias B = typeof(&f1);
    auto b0 = some(&f1);
    auto b1 = no!B;
    static assert(is(typeof(b0()) == void));
    static assert(is(typeof(b1()) == void));
}

@("Should work with disabled this")
@nogc @safe unittest {
    struct S {
        @disable this();
        this(int) {}
    }

    Optional!S a = none;
    static assert(__traits(compiles, { Optional!S a; }));
    auto b = some(S(1));
    auto c = b;
}

@("Should work with disabled post blit")
@nogc @safe unittest {
    import std.conv: to;
    static struct S {
        int i;
        @disable this(this);
        this(int i) { this.i = i; }
    }

    auto a = some(S(3));
    assert(a != none);
    assert(a.front.i == 3);
}

@("Should not destroy references")
unittest {
    class C {
        int i;
        this(int ai) { i = ai; }
    }

    C my = new C(3);
    Optional!C opt = some(my);
    assert(my.i == 3);

    opt = none;
    assert(my.i == 3);
}

@("Should assign convertaible type optional")
unittest {
    class A {}
    class B : A {}

    auto a = some(new A());
    auto b = some(new B());
    a = b;
    assert(a.front is b.front);
}

@("Should call opOpAssign if value present")
@nogc @safe unittest {
    import std.meta: AliasSeq;
    import std.traits: isMutable;
    import std.range: ElementType;
    foreach (T; QualifiedOptionalsOfQualified!int) {
        T a = 10;
        T b = none;
        static if (isMutable!(ElementType!T) && isMutable!(T)) {
            a += 10;
            b += 10;
            assert(a == some(20));
            assert(b == none);
            a -= 5;
            b -= 5;
            assert(a == some(15));
            assert(b == none);
            a %= 2;
            b %= 2;
            assert(a == some(1));
            assert(b == none);
        } else {
            static assert(!__traits(compiles, { a += 10; b += 10; } ));
            static assert(!__traits(compiles, { a -= 10; b -= 10; } ));
            static assert(!__traits(compiles, { a %= 10; b %= 10; } ));
        }
    }
}

@("Should work on arrays")
unittest {
    foreach (T; QualifiedAlisesOf!(int[])) {
        T data = [1, 2];

        auto a = some(data);
        auto b = no!T;

        assert(a[0] == some(1));
        assert(b[0] == none);
        assert(a[1] == some(2));
        assert(b[1] == none);

        // Invalid index
        assert(a[2] == none);
        assert(b[2] == none);

        // Slice
        assert(a[] == data);
        assert(b[] == none);

        // opSlice
        assert(a[0..1] == data[0..1]);
        assert(b[0..1] == none);

        // Invalid slice
        assert(a[0..7] == none);
        assert(b[0..7] == none);

        // opDollar
        assert(a[0 .. $] == data);
        assert(b[0 .. $] == none);
    }
}

@("Should compare with other ranges")
unittest {
    import std.algorithm: map, filter;
    auto a = some(1);

    assert(a == [1]);
    assert(a == [1].map!"a");
    assert(a == [1].filter!"true");
}

@("Should maintain empty state after being assigned to another optional")
unittest {
    Optional!string makeNone() {
        Optional!string v;
        return v;
    }
    Optional!string makeSome() {
        auto v = Optional!string("hi");
        return v;
    }
    Optional!string o;
    o = makeNone();
    assert(o.empty);
    o = makeSome();
    assert(!o.empty);
}

@("Should handle nulls with array of pointers")
@safe unittest {
    struct S {
        int i;
    }

    auto a = [new S(1), new S(2)].some;
    auto b = [new S(1), new S(2), null].some;
    auto c = [new S(1), new S(2), new S(3)].some;

    assert(a[2] == none);
    assert(b[2] == none);
    assert(c[2] != none);
}

@("should throw if out of range")
unittest {
    import core.exception: AssertError;
    auto a = no!int;
    bool thrown = false;
    try {
        cast(void)a.front;
    } catch (AssertError err) {
        thrown = true;
    }
    assert(thrown);
}

@("should work with const Nullable")
unittest {
    import std.typecons: nullable;
    const a = 3.nullable;
    static assert(__traits(compiles, { auto b = a.toOptional; } ));
}

@("should work with assigning of @disabled lvalue")
unittest {
    struct S {
        @disable this(this);
    }

    Optional!S fun() { return some(S()); }

    Optional!S b;
    b = fun;
}

@("Should assign a const")
unittest {
    const b = 3;
    Optional!int a;
    a = some(b);
}

@("Should work with memoize") {
    import std.functional: memoize;
    static assert(__traits(compiles, {
        alias testMemo = memoize!(() => some(1));
    }));
}
