use v6;

unit class IO::Blob is IO::Handle;

constant LF = "\n".encode;
constant TAB = "\t".encode;
constant SPACE = " ".encode;

has int $!pos; # TODO
has int $.ins is rw;
has Blob $.data is rw;

method new(Blob $data = Buf.new) {
    return self.bless(:$data, pos => 0, ins => 0);
}

method get() {
    if self.eof {
        return Nil;
    }

    # TODO other separator
    my $i = $!pos;
    my $len = $.data.elems;
    loop (; $i < $len; $i++) {
        if ($.data.subbuf($i, 1) eq LF) {
            last;
        }
    }

    my $line;
    if ($i < $len) {
        $line = $.data.subbuf($!pos, $i - $!pos + 1);
        $!pos = $i + 1;
    } else {
        $line = $.data.subbuf($!pos, $i - $!pos);
        $!pos = $len;
    }
    return $line;
}

method getc() {
    if self.eof {
        return Nil;
    }

    my $char = $.data.subbuf($!pos++, 1);
    # TODO ins

    return $char;
}

method eof() {
    return $!pos >= $.data.elems;
}

method lines($limit = Inf) {
    my $line;
    my @lines;
    loop (;;) {
        my $line = self.get;
        if (!$line.Bool) {
            last;
        }
        @lines.push($line)
    }
    return @lines;
}

method word() {
    if self.eof {
        return Nil;
    }

    # TODO other separator
    my $i = $!pos;
    my $len = $.data.elems;
    loop (; $i < $len; $i++) {
        my $char = $.data.subbuf($i, 1);
        if ($char eq LF || $char eq TAB || $char eq SPACE) {
            last;
        }
    }

    my $buf;
    if ($i < $len) {
        $buf = $.data.subbuf($!pos, $i - $!pos + 1);
        $!pos = $i + 1;
    } else {
        $buf = $.data.subbuf($!pos, $i - $!pos);
        $!pos = $len;
    }
    return $buf;
}

method words($count = Inf) {
    my $word;
    my @words;
    loop (;;) {
        my $word = self.word;
        if (!$word.Bool) {
            last;
        }
        @words.push($word)
    }
    return @words;
}

method print(*@text) returns Bool {
    my $data = $.data;
    for (@text) -> $text {
        $data ~= $text;
    }
    $data ~= LF; # TODO

    $!pos = $data.elems;
    $.data = $data;

    return True;
}

method read(Int(Cool:D) $bytes) {
    my $read = $.data.subbuf($!pos, $bytes);
    $!pos += $read.elems;
    return $read;
}

method write(Blob:D $buf) {
    self.print($buf);
    return True;
}

method seek(int $pos, int $whence) { # should use enum?
    my $eofpos = $.data.elems;

    # Seek:
    given $whence {
        when 0 { $!pos = $pos } # SEEK_SET
        when 1 { $!pos += $pos } # SEEK_CUR
        when 2 { $!pos = $eofpos + $pos } #SEEK_END
        default { die "badd seek whence ($whence)" }
    }

    # Fixup
    if ($!pos < 0) { $!pos = 0 }
    if ($!pos > $eofpos) { $!pos = $eofpos }

    return True;
}

method tell(IO::Handle:D:) returns Int {
    return $!pos;
}

proto method slurp-rest(|) { * }

multi method slurp-rest(IO::Handle:D: :$bin!) returns Buf {
    my $buf := buf8.new();

    my $read = $.data.subbuf($!pos);
    say $read;
    $!pos += $read.elems;
    #TODO ins

    return $buf ~ $read;
}

multi method slurp-rest(IO::Handle:D: :$enc) returns Str {
    my $read = $.data.decode($enc);
    $!pos = $.data.elems;
    #TODO ins

    return $read;
}

method close {
    $.data = Nil;
    $!pos = -1;
    $.ins = -1;
}

method setpos(int $pos) {
    return self.seek(0, 0);
}

method getpos {
    return self.tell;
}

