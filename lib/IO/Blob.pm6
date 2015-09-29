use v6;

unit class IO::Blob is IO::Handle;

constant EMPTY = "".encode;
constant LF = "\n".encode;
constant TAB = "\t".encode;
constant SPACE = " ".encode;

has Int $!pos .= new;
has Int $.ins is rw .= new;
has Blob $.data is rw;
has Bool $!is_closed = False;

method new(Blob $data = Buf.new) {
    return self.bless(:$data, pos => 0, ins => 1);
}

method get() {
    if self.eof {
        return EMPTY;
    }

    # TODO other separator
    my $i = $!pos;
    my $len = $.data.elems;
    loop (; $i < $len; $i++) {
        if ($.data.subbuf($i, 1) eq LF) {
            $.ins++;
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
        return EMPTY;
    }

    my $char = $.data.subbuf($!pos++, 1);

    # TODO other separator
    if ($char eq LF) {
        $.ins++;
    }

    return $char;
}

method lines($limit = Inf) {
    my $line;
    my @lines;
    loop (my $i = 0; $i < $limit; $i++) {
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
        return EMPTY;
    }

    # TODO other separator
    my $i = $!pos;
    my $len = $.data.elems;
    loop (; $i < $len; $i++) {
        my $char = $.data.subbuf($i, 1);
        if ($char eq TAB || $char eq SPACE) {
            last;
        } elsif ($char eq LF) {
            $.ins++;
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
    loop (my $i = 0; $i < $count; $i++) {
        my $word = self.word;
        if (!$word.Bool) {
            last;
        }
        @words.push($word)
    }
    return @words;
}

method print(*@text) returns Bool {
    for (@text) -> $text {
        self.write($text.encode)
    }

    return True;
}

method read(Int(Cool:D) $bytes) {
    if self.eof {
        return EMPTY;
    }

    my $read = $.data.subbuf($!pos, $bytes);
    $!pos += $read.elems;

    # TODO ins

    return $read;
}

method write(Blob:D $buf) {
    my $data = $.data ~ $buf ~ LF;
    $!pos = $data.elems;
    $.data = $data;

    # TODO ins

    return True;
}

method seek(int $pos, int $whence) { # should use enum?
    my $eofpos = $.data.elems;

    # Seek:
    given $whence {
        when 0 { $!pos = $pos } # SEEK_SET
        when 1 { $!pos += $pos } # SEEK_CUR
        when 2 { $!pos = $eofpos + $pos } #SEEK_END
        default { die "bad seek whence ($whence)" }
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
    my $buf := Buf.new();

    if self.eof {
        return $buf;
    }

    my $read = $.data.subbuf($!pos);
    $!pos += $.data.elems;

    #TODO ins

    return $buf ~ $read;
}

multi method slurp-rest(IO::Handle:D: :$enc) returns Str {
    if self.eof {
        return "";
    }

    my $read = $.data.subbuf($!pos).decode($enc);
    $!pos = $.data.elems;

    #TODO ins

    return $read;
}

method eof() {
    return $!is_closed || $!pos >= $.data.elems;
}

method close() {
    $.data = Nil;
    $!pos = Nil;
    $.ins = Nil;
    $!is_closed = True;
}

method is_closed() {
    return $!is_closed;
}

