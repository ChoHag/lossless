input rboxes

beginfig(1)
        defaultdx := defaultdy := 5bp;

        circleit.BEGIN(btex \vbox{\moveright 3bp\hbox{Begin}\hbox{Return}} etex);
        BEGIN.c = (18, 27);
        drawboxed(BEGIN);

        boxit.IN(btex IN etex);
        IN.c = (-18, -9);
        drawboxed(IN);

        boxit.OUT(btex OUT etex);
        OUT.c = (54, -9);
        drawboxed(OUT);

        boxit.LOOKUP(btex LOOKUP etex);
        LOOKUP.c = (27, 40.5);
        fixsize(LOOKUP); fixpos(LOOKUP);
        forsuffixes s=LOOKUP: draw pic_mac_.s rotated 90; draw bpath.s rotated 90; endfor

        rboxit.Combine_Start(btex Combine\_Start etex);
        rboxit.Combine_Dispatch(btex Combine\_Dispatch etex);
        rboxit.Combine_Primitive(btex Combine\_Primitive etex);
        rboxit.Combine_Applicative(btex Combine\_Applicative etex);
        rboxit.Combine_Continue(btex Combine\_Continue etex);
        rboxit.Combine_Pair(btex Combine\_Pair etex);
        rboxit.Combine_Build(btex Combine\_Build etex);
        rboxit.Combine_Ready(btex Combine\_Ready etex);
        rboxit.Combine_Operate(btex Combine\_Operate etex);
        rboxit.Combine_Finish(btex Combine\_Finish etex);
        Combine_Start.c       = (  0, 180);
        Combine_Dispatch.c    = ( 36, 108);
        Combine_Primitive.c   = (162, 135);
        Combine_Applicative.c = (162,  81);
        Combine_Continue.c    = (234, 108);
        Combine_Build.c       = (234, 162);
        Combine_Pair.c        = (342, 108);
        Combine_Ready.c       = (288,  72);
        Combine_Operate.c     = (297,  36);
        Combine_Finish.c      = (108,  18);
        drawboxed(Combine_Start);
        drawboxed(Combine_Dispatch);
        drawboxed(Combine_Primitive);
        drawboxed(Combine_Applicative);
        drawboxed(Combine_Continue);
        drawboxed(Combine_Pair);
        drawboxed(Combine_Build);
        drawboxed(Combine_Ready);
        drawboxed(Combine_Operate);
        drawboxed(Combine_Finish);

        boxit.EVALUATE_COMBINER(btex EVALUATE etex);
        EVALUATE_COMBINER.c = (54, 144);
        drawboxed(EVALUATE_COMBINER);

        boxit.EVALUATE_ARGUMENT(btex EVALUATE? etex);
        EVALUATE_ARGUMENT.c = (342, 162);
        drawboxed(EVALUATE_ARGUMENT);

        boxit.MAGIC(btex MAGIC etex);
        MAGIC.c = (189, 18);
        drawboxed(MAGIC);

        drawarrow IN.c .. BEGIN.c
                cutbefore bpath.IN cutafter bpath.BEGIN;

        drawarrow BEGIN.c .. OUT.c
                cutbefore bpath.BEGIN cutafter bpath.OUT;

        drawarrow BEGIN.c {dir 135} .. LOOKUP.c rotated 90 {dir -135}
                cutbefore bpath.BEGIN cutafter bpath.LOOKUP rotated 90;

        drawarrow LOOKUP.c rotated 90 {dir -45} .. BEGIN.c {dir 45}
                cutbefore bpath.LOOKUP rotated 90 cutafter bpath.BEGIN;

        drawarrow BEGIN.c {dir 135}              .. Combine_Start.c
                cutbefore bpath.BEGIN               cutafter bpath.Combine_Start;

        drawarrow Combine_Start.c {dir 0}        .. EVALUATE_COMBINER.c {dir -90}
                cutbefore bpath.Combine_Start       cutafter bpath.EVALUATE_COMBINER;
        drawarrow EVALUATE_COMBINER.c {dir 45}   .. Combine_Dispatch.c {dir -90}
                cutbefore bpath.EVALUATE_COMBINER   cutafter bpath.Combine_Dispatch;

        drawarrow Combine_Dispatch.c {dir 0}     .. Combine_Primitive.c {dir 45}
                cutbefore bpath.Combine_Dispatch    cutafter bpath.Combine_Primitive;
        drawarrow Combine_Dispatch.c {dir 0}     .. Combine_Applicative.c {dir -45}
                cutbefore bpath.Combine_Dispatch    cutafter bpath.Combine_Applicative;
        drawarrow Combine_Primitive.c {dir 0}    .. Combine_Continue.c {dir -67.5}
                cutbefore bpath.Combine_Primitive   cutafter bpath.Combine_Continue;
        drawarrow Combine_Applicative.c {dir 0}  .. Combine_Continue.c {dir 67.5}
                cutbefore bpath.Combine_Applicative cutafter bpath.Combine_Continue;

        drawarrow Combine_Continue.c {dir 0}     .. Combine_Pair.c
                cutbefore bpath.Combine_Continue    cutafter bpath.Combine_Pair;
        drawarrow Combine_Pair.c                 .. EVALUATE_ARGUMENT.c
                cutbefore bpath.Combine_Pair        cutafter bpath.EVALUATE_ARGUMENT;
        drawarrow EVALUATE_ARGUMENT.c            .. Combine_Build.c
                cutbefore bpath.EVALUATE_ARGUMENT   cutafter bpath.Combine_Build;
        drawarrow Combine_Build.c                .. Combine_Continue.c
                cutbefore bpath.Combine_Build       cutafter bpath.Combine_Continue;

        drawarrow Combine_Continue.c {dir 0}     .. Combine_Ready.c {dir -135}
                cutbefore bpath.Combine_Continue    cutafter bpath.Combine_Ready;
        drawarrow Combine_Ready.c {dir -45}      .. Combine_Operate.c {dir 45}
                cutbefore bpath.Combine_Ready       cutafter bpath.Combine_Operate;

        drawarrow Combine_Dispatch.c {dir -67.2} .. Combine_Operate.c {dir 0}
                cutbefore bpath.Combine_Dispatch    cutafter bpath.Combine_Operate;

        drawarrow Combine_Operate.c {dir 180}    .. MAGIC.c {dir 168.75}
                cutbefore bpath.Combine_Operate     cutafter bpath.MAGIC;
        drawarrow MAGIC.c {dir 180}              .. Combine_Finish.c {dir 180}
                cutbefore bpath.MAGIC               cutafter bpath.Combine_Finish;
        drawarrow Combine_Finish.c {dir 180}     .. BEGIN.c {dir 180}
                cutbefore bpath.Combine_Finish      cutafter bpath.BEGIN;

endfig;
end;
