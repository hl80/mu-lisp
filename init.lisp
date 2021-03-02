(define t-p (function (x)
		      (if x t)))

(define and (macro (a b)
		   (list if a (list t-p b))))

(define or (macro (a b)
		  (list if a t (list t-p b))))

(define with* (macro (envs body)
		     (list 'with (run envs) body)))

(define apply (function (func args)
		     (run (pair func args))))

(define reduce (function (func lst accum)
			 (pack
			  (if lst
			      (let ((a (func (first lst) accum)))
				(reduce func (rest lst) a))
			      accum))))

(define map-list (function (func lst)
			   (if lst
			       (pair (func (first lst)) (map-list func (rest lst))))))

(define pair-up-one (function (lsts)
			      (if lsts
				  (pair (first (first lsts)) (pair-up-one (rest lsts))))))

(define pair-up (function (lsts)
			  (if (reduce and lsts t)
			      (pair (pair-up-one lsts) (pair-up (map-list (function (x) (rest x)) lsts))))))

(define map-lists (function (func lsts)
			    (map-list (function (x) (apply func x)) (pair-up lsts))))
